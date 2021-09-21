from brownie import *
from config import (
    BADGER_DEV_MULTISIG,
    WANT,
    LP_COMPONENT,
    REWARD_TOKEN,
    PROTECTED_TOKENS,
    FEES
)


def main():
    return test()


def test():
    deployed = run("mock_deploy")

    d = deployed.deployer.address
    s = deployed.strategy.address

    print("Balance Of Want ", deployed.strategy.balanceOfWant())
    print("Balance of Pool ", deployed.strategy.balanceOfPool())
    print("Depositing...")

    deployed.strategy.testDeposit(deployed.strategy.balanceOfWant())

    chain.sleep(86400)
    chain.mine()

    tx = deployed.strategy.harvest()

    # deployed.strategy.tend()

    # toWithdraw = deployed.strategy.balanceOfPool() // 2

    # tx = deployed.strategy.testWithdraw(toWithdraw)

    # print("Return value", tx.return_value)
    print(tx.traceback())
