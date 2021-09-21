// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./IConverterAnchor.sol";

import "./IDSToken.sol";
import "./IReserveToken.sol";

import "./IOwned.sol";

/*
    Liquidity Protection Store interface
*/
interface ILiquidityProtectionStore is IOwned {
    function withdrawTokens(
        IReserveToken _token,
        address _to,
        uint256 _amount
    ) external;

    function protectedLiquidity(uint256 _id)
        external
        view
        returns (
            address,
            IDSToken,
            IReserveToken,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function removeProtectedLiquidity(uint256 _id) external;

    function protectedLiquidityIds(address _provider)
        external
        view
        returns (uint256[] memory);
}
