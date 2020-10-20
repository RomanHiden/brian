# brownie console --network mainnet-fork

from brownie import accounts, Contract, BZxFlashLoanerUNIKYBER

def test_flash_uni():

	# token contracts
	bzx, dai, idai, usdc = (BZxFlashLoanerUNIKYBER.deploy({'from':accounts[0]}), Contract.from_explorer("0x6b175474e89094c44da98b954eedeac495271d0f"), Contract.from_explorer("0x6b093998D36f2C7F0cc359441FBB24CC629D5FF0"), Contract.from_explorer("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"))

	# approve, swap ether for tokens, transfer to contract
	((dai.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]}), usdc.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]})), (bzx.swapEtherToToken(dai, accounts[0], {'from':accounts[0], 'value':2000000000000000000}), bzx.swapEtherToToken(usdc, accounts[0], {'from':accounts[0], 'value':2000000000000000000})), (dai.transfer(bzx, dai.balanceOf(accounts[0]), {'from':accounts[0]}), usdc.transfer(bzx, usdc.balanceOf(accounts[0]), {'from':accounts[0]})))

	(bzx.swapEtherToToken(dai, accounts[0], {'from':accounts[0], 'value':20000000000000000000}), bzx.swapEtherToToken(usdc, accounts[0], {'from':accounts[0], 'value':20000000000000000000}))

	##	print balances
	for key, value in {"ether":accounts[0].balance()/10**18, "contract-dai":dai.balanceOf(bzx)/10**18, "account-dai":dai.balanceOf(accounts[0])/10**18, "contract-usdc":usdc.balanceOf(bzx)/10**6, "account-usdc":usdc.balanceOf(accounts[0])/10**6, "total":(dai.balanceOf(bzx)/10**18 + dai.balanceOf(accounts[0])/10**18 + usdc.balanceOf(bzx)/10**6 + usdc.balanceOf(accounts[0])/10**6)}.items(): print(key, value)

	# tx = bzx.doStuffWithFlashLoan(dai, idai, ((10**18)) * 40000), {'from':accounts[0]})


def test_liquidation():

	aave, aavelpc, bat, lend, link, yfi, tusd, wbtc, bzx, dai, idai, usdc = (Contract.from_explorer("0x398eC7346DcD622eDc5ae82352F02bE94C62d119"),Contract.from_explorer("0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3"),Contract.from_explorer("0x0D8775F648430679A709E98d2b0Cb6250d2887EF"),Contract.from_explorer("0x80fB784B7eD66730e8b1DBd9820aFD29931aab03"),Contract.from_explorer("0x514910771AF9Ca656af840dff83E8264EcF986CA"),Contract.from_explorer("0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e"),Contract.from_explorer("0x0000000000085d4780B73119b644AE5ecd22b376"),Contract.from_explorer("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"), BZxFlashLoanerUNIKYBER.deploy({'from':accounts[0]}), Contract.from_explorer("0x6b175474e89094c44da98b954eedeac495271d0f"), Contract.from_explorer("0x6b093998D36f2C7F0cc359441FBB24CC629D5FF0"), Contract.from_explorer("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"))

	for contract in (bat, lend, link, yfi, tusd, wbtc, dai, idai, usdc): contract.approve(bzx, 100000000000000000000000000000000000,{'from':accounts[0]})
	for contract in (bat, lend, link, yfi, tusd, wbtc, dai, idai, usdc): contract.approve(aave, 100000000000000000000000000000000000,{'from':accounts[0]})
	for contract in (bat, lend, link, yfi, tusd, wbtc, dai, idai, usdc): contract.approve(aavelpc, 100000000000000000000000000000000000,{'from':accounts[0]})

	for token in (bat, lend, link, yfi, tusd, wbtc, dai, usdc): bzx.swapEtherToToken(token, accounts[0], {'from':accounts[0], 'value':1000000000000000000})

	for token in (bat, lend, link, yfi, tusd, wbtc, dai, usdc): token.name(), token.balanceOf(accounts[0])


def test_commands():
	tx = aave.deposit(dai, 1000000000000000000000, 0,  {'from':accounts[0]})

	tx = aave.borrow(usdc, 650000000, 1, 1, {'from':accounts[0]})

	eth = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

	tx = aave.getUserReserveData(eth, "0x12d8bBbc8C5AC5675d29694def3497ef83615F45")

	tx = aave.getUserAccountData(accounts[0])
	aave.getUserAccountData("0x618A9Df7c2Df1567583EB03926472Ffd7FcE5423")

	tx = aave.liquidationCall(link, lend", "0x7f3a19729165Ce5Bc7E902E18C7f85Dd83D84D00", 2872, True, {'from':accounts[0]})

	tx = bzx.liquidateTarget("0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", "0x12d8bBbc8C5AC5675d29694def3497ef83615F45", 9053938965937232/2, True, {'from':accounts[0]})

	tx.info()

	assert False
