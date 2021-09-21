// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStakingRewards {
    /**
     * @dev returns specific provider's pending rewards for all participating pools
     */
    function pendingRewards(address provider) external view returns (uint256);

    /**
     * @dev returns specific provider's total claimed rewards from all participating pools
     */
    function totalClaimedRewards(address provider)
        external
        view
        returns (uint256);

    /**
     * @dev claims pending rewards from all participating pools
     */
    function claimRewards() external returns (uint256);
}
