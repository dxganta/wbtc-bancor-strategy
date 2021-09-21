// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// import "../../deps/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBancorNetwork {
    function convertByPath(
        address[] memory path,
        uint256 amount,
        uint256 minReturn,
        address payable beneficiary,
        address affiliateAccount,
        uint256 affiliateFee
    ) external payable returns (uint256);

    function rateByPath(address[] memory _path, uint256 _amount) external view returns (uint256);
}
