pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// "SPDX-License-Identifier: Apache-2.0"

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


///////////////////////////////
interface IToken {
    function flashBorrow(uint256 borrowAmount, address borrower, address target, string calldata signature, bytes calldata data ) external payable returns (bytes memory);
}
///////////////////////////////
interface IKyber {
    function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);
    function swapTokenToEther(IERC20 token, uint tokenQty, uint minRate) external returns (uint);
    function swapTokenToToken(IERC20 src, uint srcAmount, IERC20 dest, uint minConversionRate) external returns (uint); //
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
}
///////////////////////////////

contract BZxFlashLoaner is Ownable {

    IKyber public KYBER_PROXY = IKyber(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    uint constant MAX_UINT = 2**256 - 1;
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    function getRate(ERC20 srcToken, ERC20 destToken, uint256 srcQty) public returns (uint256){
        uint256 expected;
        uint256 slippage;
        (expected, slippage) = KYBER_PROXY.getExpectedRate(srcToken, destToken, srcQty);
        return slippage;
    }

    //tx = bzx.swapEtherToToken("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", accounts[0], {'from':accounts[0], 'value':10000000000000000000})
    function swapEtherToToken(ERC20 token, address destAddress) public payable {
        uint minRate;
        (, minRate) = KYBER_PROXY.getExpectedRate(ETH_TOKEN_ADDRESS, token, msg.value);
        uint destAmount = KYBER_PROXY.swapEtherToToken.value(msg.value)(token, minRate);
        require(token.transfer(destAddress, destAmount));
    }

    //tx = bzx.swapTokenToToken("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", usdc.balanceOf(accounts[0]), "0x6b175474e89094c44da98b954eedeac495271d0f", accounts[0], {'from': accounts[0]})
    function swapTokenToToken(ERC20 srcToken, uint srcQty, ERC20 destToken, address destAddress) public {
        uint minRate;
        (, minRate) = KYBER_PROXY.getExpectedRate(srcToken, destToken, srcQty);
        require(srcToken.transferFrom(msg.sender, address(this), srcQty));
        require(srcToken.approve(address(KYBER_PROXY), 0));
        srcToken.approve(address(KYBER_PROXY), srcQty);
        uint destAmount = KYBER_PROXY.swapTokenToToken(srcToken, srcQty, destToken, minRate);
        require(destToken.transfer(destAddress, destAmount));
    }

    function trade(IERC20 srcToken, uint srcQty, IERC20 destToken) internal {
      emit BalanceOf(srcToken.balanceOf(address(this)));
      swapTokenToToken(srcToken, srcQty, destToken, address(this));
      emit BalanceOf(srcToken.balanceOf(address(this)));
      swapOnUniswapv2(address(destToken), destToken.balanceOf(address(this)), address(srcToken));
      emit BalanceOf(srcToken.balanceOf(address(this)));
    }


    function executeOperation(address loanToken, address iToken, uint256 loanAmount ) external returns (bytes memory success) {
        emit BalanceOf(IERC20(loanToken).balanceOf(address(this)));
        emit ExecuteOperation(loanToken, iToken, loanAmount);
        /////////////////////////////////////////////////////
        
        /////////////////////////////////////////////////////
        repayFlashLoan(loanToken, iToken, loanAmount);
        return bytes("1");
    }

    function doStuffWithFlashLoan(address token, address iToken, uint256 amount) external onlyOwner {
        bytes memory result;
        emit BalanceOf(IERC20(token).balanceOf(address(this)));
        result = initiateFlashLoanBzx(token, iToken, amount);
        emit BalanceOf(IERC20(token).balanceOf(address(this)));
        if (hashCompareWithLengthCheck(bytes("1"), result)) {
            revert("failed executeOperation");
        }
    }

    function hashCompareWithLengthCheck(bytes memory a, bytes memory b) pure internal returns (bool) {
        if (a.length != b.length) {
            return false;
        } else {
            return keccak256(a) == keccak256(b);
        }
    }

    function repayFlashLoan(address loanToken,address iToken,uint256 loanAmount) internal {
      IERC20(loanToken).transfer(iToken, loanAmount);
    }


    function initiateFlashLoanBzx(address loanToken,address iToken,uint256 flashLoanAmount) internal returns (bytes memory success) {
        IToken iTokenContract = IToken(iToken);
        return iTokenContract.flashBorrow(flashLoanAmount,address(this),address(this),"",abi.encodeWithSignature("executeOperation(address,address,uint256)",loanToken,iToken,flashLoanAmount));
    }


    event ExecuteOperation(
        address loanToken,
        address iToken,
        uint256 loanAmount
    );

    event BalanceOf(uint256 balance);
}
