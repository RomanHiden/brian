# brownie console --network mainnet-fork

from brownie import accounts, Contract, bzxFlashlArb

def test_aave_flash():

        weth, arb = (Contract.from_explorer("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"), bzxFlashlArb.deploy({'from':accounts[0]}))


        usdc = Contract.from_explorer("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")


        iUSDC = Contract.from_explorer("0x32e4c68b3a4a813b710595aeba7f6b7604ab9c15")
        iETH = Contract.from_explorer("0xb983e01458529665007ff7e0cddecdb74b967eb6")


        
        #doStuffWithFlashLoan(address loantoken, address iToken, uint256 amount, address collateral)


        tx = arb.doStuffWithFlashLoan("0xdac17f958d2ee523a2206206994597c13d831ec7", "0x7e9997a38A439b2be7ed9c9C4628391d3e055D48", 100000000000, usdc,    {'from':accounts[0]})

        tx.info()

        assert False
