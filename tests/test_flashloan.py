#!/usr/bin/python3
import pytest
import brownie
from brownie import network, Contract, Wei, reverts
from brownie.network.contract import InterfaceContainer


def loadContractFromEtherscan(address, alias):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_explorer(address)
        contract.set_alias(alias)
        return contract


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert network.show_active() == "mainnet-fork"


@pytest.fixture(scope="module")
def flashLoaner(accounts, BZxFlashLoaner):
    proxy = accounts[0].deploy(BZxFlashLoaner)
    return Contract.from_abi("flashLoaner", proxy.address, BZxFlashLoaner.abi, accounts[0])


@pytest.fixture(scope="module")
def DAI():
    return loadContractFromEtherscan("0x6b175474e89094c44da98b954eedeac495271d0f", "DAI")


@pytest.fixture(scope="module")
def USDC():
    return loadContractFromEtherscan("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "USDC")


@pytest.fixture(scope="module")
def iDAI():
    return loadContractFromEtherscan("0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0", "iDAI")


@pytest.fixture(scope="module")
def KYBER():
    return loadContractFromEtherscan("0x9AAb3f75489902f3a48495025729a0AF77d4b11e", "kyber")


def testLoaner(accounts, requireMainnetFork, flashLoaner, iDAI, DAI, USDC, KYBER):
    print("flashLoaner.address", flashLoaner.address)
    # tx1 = flashLoaner.swapEtherToToken(USDC.address, accounts[0], {
    #                          'from': accounts[0], 'value': Wei('1 ether')})
    
    # tx2 = flashLoaner.swapEtherToToken(DAI.address,flashLoaner.address, {
    #                          'from': accounts[0], 'value': 10000000000000000000})

        
    # I need below DAI on flashLoaner.address to cover overall net loss due to commision etc.
    tx3 = flashLoaner.swapEtherToToken(DAI.address, flashLoaner.address, {
                             'from': accounts[0], 'value': Wei('1 ether')})

    # print("balanceOf", USDC.balanceOf(flashLoaner.address))
    # print("balanceOf", DAI.balanceOf(accounts[0]))
    # print("balanceOf", DAI.balanceOf(flashLoaner.address))



    # USDC.approve(KYBER.address, 99999999999999999999999999999999999999999, {'from': accounts[0]})
    # DAI.approve(KYBER.address, 99999999999999999999999999999999999999999, {'from': accounts[0]})
    
    
    # asdf = KYBER.getExpectedRate(DAI, USDC, 100000000000000000);
    # print("asdf", asdf)
    # tx = KYBER.swapTokenToToken(
    #     DAI,
    #     100000000000000000,
    #     USDC,
    #     asdf[1],
    #     {'from': accounts[0]}
    # )

    # I am passing amount without precision e.g 100$, please not I am requesting flash loan more than I have on the account by tx3
    tx = flashLoaner.doStuffWithFlashLoan(DAI.address, iDAI.address, 1000, {'from': accounts[0]})
    
    tx.info()


    assert False
