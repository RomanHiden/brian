# brownie console --network mainnet-fork
#set WEB3_INFURA_PROJECT_ID=4766db13619a4175aa7cf834d3eeae42
#set ETHERSCAN_TOKEN=D57I32YGBARF6I4XSGA3QNZHYY1Z3WGM64

from brownie import accounts, Contract, BZxFlashLoanerUNIKYBER


def swapping():
	# call contract and get the rate of WETH/DAI
	bzx = BZxFlashLoaner.deploy({'from':accounts[0]})
	#tx = bzx.getRate("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2","0x6b175474e89094c44da98b954eedeac495271d0f",  100000000000000000000,{'from':accounts[0]})

	# deploy dai contract and swap eth for dai
	dai = Contract.from_explorer("0x6b175474e89094c44da98b954eedeac495271d0f")
	tx = bzx.swapEtherToToken("0x6b175474e89094c44da98b954eedeac495271d0f", accounts[0], {'from':accounts[0], 'value':10000000000000000000})

	# deploy usdc contract and swap eth for usdc
	usdc = Contract.from_explorer("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
	tx = bzx.swapEtherToToken("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", accounts[0], {'from':accounts[0], 'value':10000000000000000000})

	#approvals
	tx = dai.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]})
	tx = usdc.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]})

	#swap dai for usdc
	tx = bzx.swapTokenToToken("0x6b175474e89094c44da98b954eedeac495271d0f", dai.balanceOf(accounts[0]), "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", accounts[0], {'from': accounts[0]})
	#swap usdc for dai
	tx = bzx.swapTokenToToken("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", usdc.balanceOf(accounts[0]), "0x6b175474e89094c44da98b954eedeac495271d0f", accounts[0], {'from': accounts[0]})

def flash_kyber():
	# deploy bzx contract
	bzx = BZxFlashLoaner.deploy({'from':accounts[0]})

	# create usdc and dai objects
	dai = Contract.from_explorer("0x6b175474e89094c44da98b954eedeac495271d0f")
	usdc = Contract.from_explorer("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")

	#dai = Contract.from_abi("erc20", address="0x6b175474e89094c44da98b954eedeac495271d0f", abi=interface.ERC20.abi,owner=accounts[0])
	#usdc = Contract.from_abi("erc20", address="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", abi=interface.ERC20.abi,owner=accounts[0])

	# approve bzx contract to spend dai and usdc from accounts[0]
	tx = dai.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]})
	tx = usdc.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]})

	# swap ether for usdc and dai
	tx = bzx.swapEtherToToken("0x6b175474e89094c44da98b954eedeac495271d0f", accounts[0], {'from':accounts[0], 'value':10000000000000000000})
	tx = bzx.swapEtherToToken("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", accounts[0], {'from':accounts[0], 'value':10000000000000000000})

	# send dai and usdc to the bzx contract
	tx = dai.transfer(bzx, dai.balanceOf(accounts[0]), {'from':accounts[0]})
	tx = usdc.transfer(bzx, usdc.balanceOf(accounts[0]), {'from':accounts[0]})

	# initiate flash loan that has kyber swaps inside
	tx = bzx.doStuffWithFlashLoan("0x6B175474E89094C44Da98b954EedeAC495271d0F", "0x6b093998D36f2C7F0cc359441FBB24CC629D5FF0", 1000, {'from': accounts[0]})





# this is a standard flash loan
# tx = bzx.doStuffWithFlashLoan("0x6b175474e89094c44da98b954eedeac495271d0f", "0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0", 10000000000000000000, {'from': accounts[0]})

#			(dai.balanceOf(bzx2), dai.balanceOf(accounts[0]), usdc.balanceOf(bzx2), usdc.balanceOf(accounts[0]))
#           dai.balanceOf(accounts[0])
#			usdc.balanceOf(bzx)
#           usdc.balanceOf(accounts[0])
#           accounts[0].balance()

	#dai = Contract.from_abi("erc20", address="0x6b175474e89094c44da98b954eedeac495271d0f", abi=interface.ERC20.abi,owner=accounts[0])
	#usdc = Contract.from_abi("erc20", address="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", abi=interface.ERC20.abi,owner=accounts[0])



def test_flash_uni():
	# deploy bzx uni kyber contract
	bzx = BZxFlashLoanerUNIKYBER.deploy({'from':accounts[0]})

	bzx2 = BZxFlashLoaner.deploy({'from':accounts[0]})

	# create usdc and dai objects
	dai, idai, usdc = (Contract.from_explorer("0x6b175474e89094c44da98b954eedeac495271d0f"), Contract.from_explorer("0x6b093998D36f2C7F0cc359441FBB24CC629D5FF0"), Contract.from_explorer("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"))

	# approve bzx contract to spend dai and usdc from accounts[0]
	tx = dai.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]})
	tx = usdc.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]})

	# swap ether for usdc and dai
	tx = bzx.swapEtherToToken("0x6b175474e89094c44da98b954eedeac495271d0f", accounts[0], {'from':accounts[0], 'value':1000000000000000000})
	tx = bzx.swapEtherToToken("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", accounts[0], {'from':accounts[0], 'value':1000000000000000000})


	# send dai and usdc to the bzx contract
	tx = dai.transfer(bzx, dai.balanceOf(accounts[0])/1.5, {'from':accounts[0]})
	tx = usdc.transfer(bzx, usdc.balanceOf(accounts[0])/1.5, {'from':accounts[0]})

	## transfer dai/usdc to contract
	(dai.transfer(bzx, dai.balanceOf(accounts[0])/2, {'from':accounts[0]}), usdc.transfer(bzx, usdc.balanceOf(accounts[0])/2, {'from':accounts[0]}))

	##	print balances
	for key, value in {"ether":accounts[0].balance()/10**18, "contract-dai":dai.balanceOf(bzx)/10**18, "account-dai":dai.balanceOf(accounts[0])/10**18, "contract-usdc":usdc.balanceOf(bzx)/10**6, "account-usdc":usdc.balanceOf(accounts[0])/10**6, "total":(dai.balanceOf(bzx)/10**18 + dai.balanceOf(accounts[0])/10**18 + usdc.balanceOf(bzx)/10**6 + usdc.balanceOf(accounts[0])/10**6)}.items(): print(key, value)
	

	# initiate flash loan that has kyber swaps inside
	tx = bzx.doStuffWithFlashLoan(dai, idai, 1000, {'from': accounts[0]})



	#################### swap 1/2 ETH for usdc/dai, dai/usdc approve bzx, transfer 1/2 dai/usdc to bzx  #######################################
	(bzx.swapEtherToToken("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", accounts[0], {'from':accounts[0], 'value':1000000000000000000}), bzx.swapEtherToToken("0x6b175474e89094c44da98b954eedeac495271d0f", accounts[0], {'from':accounts[0], 'value':1000000000000000000}), usdc.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]}), dai.approve(bzx.address, 100000000000000000000000000000000000,{'from':accounts[0]}), dai.transfer(bzx, dai.balanceOf(accounts[0])/2, {'from':accounts[0]}), usdc.transfer(bzx, usdc.balanceOf(accounts[0])/2, {'from':accounts[0]}))














