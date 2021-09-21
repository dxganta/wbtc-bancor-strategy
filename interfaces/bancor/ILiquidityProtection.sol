// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./IReserveToken.sol";

import "./IConverterAnchor.sol";

/*
    Liquidity Protection interface
*/
interface ILiquidityProtection {
    function addLiquidity(
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function removeLiquidity(uint256 id, uint32 portion) external;

    /**
     * @dev returns the expected/actual amounts the provider will receive for removing liquidity
     * it's also possible to provide the remove liquidity time to get an estimation
     * for the return at that given point
     *
     * @param id position id
     * @param portion portion of liquidity to remove, in PPM
     * @param removeTimestamp time at which the liquidity is removed
     *
     * @return expected return amount in the reserve token
     * @return actual return amount in the reserve token
     * @return compensation in the network token
     */
    function removeLiquidityReturn(
        uint256 id,
        uint32 portion,
        uint256 removeTimestamp
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}
