// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "../deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../deps/@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "../deps/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/bancor/ILiquidityProtection.sol";
import "../interfaces/bancor/IConverterAnchor.sol";
import "../interfaces/bancor/IReserveToken.sol";
import "../interfaces/bancor/IStakingRewards.sol";
import "../interfaces/bancor/IBancorNetwork.sol";
import "../interfaces/bancor/ILiquidityProtectionStore.sol";

import "../interfaces/badger/IController.sol";

import {BaseStrategy} from "../deps/BaseStrategy.sol";

contract MyStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    // address public want // Inherited from BaseStrategy, the token the strategy wants, swaps into and tries to grow
    address public LP_COMPONENT; // Token we provide liquidity with
    address public reward; // Token we farm and swap to want / LP_COMPONENT

    address public constant LIQUIDITY_PROTECTION_ADDRESS =
        0x853c2D147a1BD7edA8FE0f58fb3C5294dB07220e;
    address public constant STAKING_REWARDS_ADDRESS =
        0x5DaFb315D9C358d628FB62041104e4c5a2b3080B;
    address public constant BANCOR_NETWORK_ADDRESS =
        0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0;
    address public constant LIQUIDITY_PROTECTION_STORE =
        0xf5FAB5DBD2f3bf675dE4cB76517d4767013cfB55;

    // uint256 public wbtcPool;

    // Used to signal to the Badger Tree that rewards where sent to it
    event TreeDistribution(
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    function initialize(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian,
        address[3] memory _wantConfig,
        uint256[3] memory _feeConfig
    ) public initializer {
        __BaseStrategy_init(
            _governance,
            _strategist,
            _controller,
            _keeper,
            _guardian
        );
        /// @dev Add config here
        want = _wantConfig[0];
        LP_COMPONENT = _wantConfig[1];
        reward = _wantConfig[2];

        performanceFeeGovernance = _feeConfig[0];
        performanceFeeStrategist = _feeConfig[1];
        withdrawalFee = _feeConfig[2];

        /// @dev do one off approvals here
        IERC20Upgradeable(want).safeApprove(
            LIQUIDITY_PROTECTION_ADDRESS,
            type(uint256).max
        );
        IERC20Upgradeable(reward).safeApprove(
            BANCOR_NETWORK_ADDRESS,
            type(uint256).max
        );
        IERC20Upgradeable(LP_COMPONENT).safeApprove(
            BANCOR_NETWORK_ADDRESS,
            type(uint256).max
        );
        IERC20Upgradeable(want).safeApprove(
            BANCOR_NETWORK_ADDRESS,
            type(uint256).max
        );
    }

    /// ===== View Functions =====

    // @dev Specify the name of the strategy
    function getName() external pure override returns (string memory) {
        return "WBTC BANCOR STRATEGY";
    }

    // @dev Specify the version of the Strategy, for upgrades
    function version() external pure returns (string memory) {
        return "1.0";
    }

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public view override returns (uint256) {
        uint256 _total;
        uint256[] memory _ids =
            ILiquidityProtectionStore(LIQUIDITY_PROTECTION_STORE)
                .protectedLiquidityIds(address(this));
        for (uint256 i = 0; i < _ids.length; i++) {
            (uint256 _, uint256 claimable, uint256 __) =
                ILiquidityProtection(LIQUIDITY_PROTECTION_ADDRESS)
                    .removeLiquidityReturn(_ids[i], 1000000, now);
            _total = _total.add(claimable);
        }
        return _total;
        // return wbtcPool;
    }

    /// @dev Returns true if this strategy requires tending
    function isTendable() public view override returns (bool) {
        return true;
    }

    // @dev These are the tokens that cannot be moved except by the vault
    function getProtectedTokens()
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory protectedTokens = new address[](3);
        protectedTokens[0] = want;
        protectedTokens[1] = LP_COMPONENT;
        protectedTokens[2] = reward;
        return protectedTokens;
    }

    /// ===== Internal Core Implementations =====

    /// @dev security check to avoid moving tokens that would cause a rugpull, edit based on strat
    function _onlyNotProtectedTokens(address _asset) internal override {
        address[] memory protectedTokens = getProtectedTokens();

        for (uint256 x = 0; x < protectedTokens.length; x++) {
            require(
                address(protectedTokens[x]) != _asset,
                "Asset is protected"
            );
        }
    }

    /// @dev invest the amount of want
    /// @notice When this function is called, the controller has already sent want to this
    /// @notice Just get the current balance and then invest accordingly
    function _deposit(uint256 _amount) internal override {
        // add single sided wbtc liquidity to bancor
        ILiquidityProtection(LIQUIDITY_PROTECTION_ADDRESS).addLiquidity(
            IConverterAnchor(LP_COMPONENT),
            IReserveToken(want),
            _amount
        );

        // wbtcPool = wbtcPool.add(_amount);
    }

    /// @dev utility function to withdraw everything for migration
    function _withdrawAll() internal override {
        _withdrawSome(balanceOfPool());
    }

    /// @dev withdraw the specified amount of want, liquidate from LP_COMPONENT to want, paying off any necessary debt for the conversion
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 toWithdraw = _amount;
        uint256[] memory _ids =
            ILiquidityProtectionStore(LIQUIDITY_PROTECTION_STORE)
                .protectedLiquidityIds(address(this));
        uint256 currentId;

        while (toWithdraw > 0 && currentId < _ids.length) {
            // get amount of liquidity in that id
            (uint256 _, uint256 claimable, uint256 __) =
                ILiquidityProtection(LIQUIDITY_PROTECTION_ADDRESS)
                    .removeLiquidityReturn(_ids[currentId], 1000000, now);

            if (claimable > 0) {
                // wbtcPool = wbtcPool.sub(toWithdraw);
                if (toWithdraw <= claimable) {
                    // if toWithdraw amount is less than or equal to amount in id,  withdraw the toWithdraw amount and stop the loop.
                    uint32 _portion =
                        uint32(toWithdraw.mul(10**6).div(claimable));
                    // return _portion;
                    ILiquidityProtection(LIQUIDITY_PROTECTION_ADDRESS)
                        .removeLiquidity(_ids[currentId], _portion);
                    toWithdraw = 0;
                } else {
                    // if toWithdraw amount is greater than amount in id, withdraw the 100% portion and then go to the next id to withdraw the remaining
                    ILiquidityProtection(LIQUIDITY_PROTECTION_ADDRESS)
                        .removeLiquidity(_ids[currentId], 10**6);
                    toWithdraw = toWithdraw.sub(claimable);
                }
            }
            currentId = currentId.add(1);
        }
        return _amount;
    }

    /// @dev Harvest from strategy mechanics, realizing increase in underlying position
    function harvest() external whenNotPaused returns (uint256 harvested) {
        _onlyAuthorizedActors();

        uint256 _before = IERC20Upgradeable(want).balanceOf(address(this));

        // claim the BNT rewards
        IStakingRewards(STAKING_REWARDS_ADDRESS).claimRewards();

        uint256 rewards = IERC20Upgradeable(reward).balanceOf(address(this));

        if (rewards == 0) {
            return 0;
        }

        address[] memory swapPath = new address[](3);
        swapPath[0] = reward; // 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C // bnt
        swapPath[1] = LP_COMPONENT; // 0xFEE7EeaA0c2f3F7C7e6301751a8dE55cE4D059Ec
        swapPath[2] = want; // 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599 // wbtc

        // convert BNT rewards to WBTC
        IBancorNetwork(BANCOR_NETWORK_ADDRESS).convertByPath(
            swapPath,
            rewards,
            1, // TODO: calculate this first, to prevent front-running
            address(0),
            address(0),
            0
        );

        uint256 earned =
            IERC20Upgradeable(want).balanceOf(address(this)).sub(_before);

        /// @notice Keep this in so you get paid!
        (uint256 governancePerformanceFee, uint256 strategistPerformanceFee) =
            _processRewardsFees(earned, want);

        /// @dev Harvest event that every strategy MUST have, see BaseStrategy
        emit Harvest(earned, block.number);

        /// @dev Harvest must return the amount of want increased
        return earned;
    }

    // Alternative Harvest with Price received from harvester, used to avoid exessive front-running
    function harvest(uint256 price)
        external
        whenNotPaused
        returns (uint256 harvested)
    {}

    /// @dev Rebalance, Compound or Pay off debt here
    function tend() external whenNotPaused {
        _onlyAuthorizedActors();
        uint256 bal = balanceOfWant();

        if (bal > 0) {
            _deposit(bal);
        }
    }

    /// ===== Internal Helper Functions =====

    /// @dev used to manage the governance and strategist fee on earned rewards, make sure to use it to get paid!
    function _processRewardsFees(uint256 _amount, address _token)
        internal
        returns (uint256 governanceRewardsFee, uint256 strategistRewardsFee)
    {
        governanceRewardsFee = _processFee(
            _token,
            _amount,
            performanceFeeGovernance,
            IController(controller).rewards()
        );

        strategistRewardsFee = _processFee(
            _token,
            _amount,
            performanceFeeStrategist,
            strategist
        );
    }
}
