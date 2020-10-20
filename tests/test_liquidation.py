# brownie console --network mainnet-fork

from brownie import accounts, Contract, BZxFlashLoanerUNIKYBER


def test_liquidation():

        # create contract objects
        aave, aavelpc, bat, lend, link, yfi, tusd, wbtc, bzx, dai, idai, usdc = (Contract.from_explorer("0x398eC7346DcD622eDc5ae82352F02bE94C62d119"),Contract.from_explorer("0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3"),Contract.from_explorer("0x0D8775F648430679A709E98d2b0Cb6250d2887EF"),Contract.from_explorer("0x80fB784B7eD66730e8b1DBd9820aFD29931aab03"),Contract.from_explorer("0x514910771AF9Ca656af840dff83E8264EcF986CA"),Contract.from_explorer("0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e"),Contract.from_explorer("0x0000000000085d4780B73119b644AE5ecd22b376"),Contract.from_explorer("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"), BZxFlashLoanerUNIKYBER.deploy({'from':accounts[0]}), Contract.from_explorer("0x6b175474e89094c44da98b954eedeac495271d0f"), Contract.from_explorer("0x6b093998D36f2C7F0cc359441FBB24CC629D5FF0"), Contract.from_explorer("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"))

        # swap eth for each of the tokens needed for liquidation
        for token in (bat, lend, link, yfi, tusd, wbtc, dai, usdc): bzx.swapEtherToToken(token, accounts[0], {'from':accounts[0], 'value':1000000000000000000})

        # check token balances in accounts[0]
        # for token in (bat, lend, link, yfi, tusd, wbtc, dai, usdc): token.name(), token.balanceOf(accounts[0])

        # send tokens to my contract
        for token in (bat, lend, link, yfi, tusd, wbtc, dai, usdc): token.transfer(bzx, token.balanceOf(accounts[0]), {'from':accounts[0]})

        # check token balances in my contract
        # for token in (bat, lend, link, yfi, tusd, wbtc, dai, usdc): token.name(), token.balanceOf(bzx)

        # check the user and reserve data in the aave smart contract
        # usrctdata = aave.getUserAccountData('0xd1F560e0CdB488CD0F646642b3247136ff12FA10')
        # usrrvdata1 = aave.getUserReserveData("0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xd1F560e0CdB488CD0F646642b3247136ff12FA10")
        # usrrvdata2 = aave.getUserReserveData("0x514910771AF9Ca656af840dff83E8264EcF986CA", "0xd1F560e0CdB488CD0F646642b3247136ff12FA10")

        tx = bzx.liquidateTarget('0x6B175474E89094C44Da98b954EedeAC495271d0F','0x514910771AF9Ca656af840dff83E8264EcF986CA','0xd1F560e0CdB488CD0F646642b3247136ff12FA10', 11456036658510013, {'from':accounts[0]})
        tx = bzx.liquidateTarget('0x6B175474E89094C44Da98b954EedeAC495271d0F','0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599','0x12d8bBbc8C5AC5675d29694def3497ef83615F45',9814, {'from':accounts[0]})


        tx.info()

        assert false
