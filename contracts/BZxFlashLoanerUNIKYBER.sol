pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// "SPDX-License-Identifier: Apache-2.0"

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//////////////////////////////
interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IKyber {
    function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);
    function swapTokenToEther(IERC20 token, uint tokenQty, uint minRate) external returns (uint);
    function swapTokenToToken(IERC20 src, uint srcAmount, IERC20 dest, uint minConversionRate) external returns (uint); //
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
}

///////////////////////////////
interface IToken {
    function flashBorrow(uint256 borrowAmount, address borrower, address target, string calldata signature, bytes calldata data ) external payable returns (bytes memory);
}

contract BZxFlashLoanerUNIKYBER is Ownable {

    IKyber public KYBER_PROXY = IKyber(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    address payable internal uniswapV2_routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint constant MAX_UINT = 2**256 - 1;
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    event paramsLog(
      address fromToken,
      uint256 fromTokenAmount,
      address tradeToken,
      uint256 tradeTokenAmount
    );


    function executeOperation2(address loanToken, address iToken, uint256 loanAmount ) external returns (bytes memory success) {
        emit BalanceOf(IERC20(loanToken).balanceOf(address(this)), "token");
        emit ExecuteOperation(loanToken, iToken, loanAmount);
        /////////////////////////////////////////////////////

        swapTokenToToken(ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), loanAmount, ERC20(loanToken), address(this));
        swapOnUniswapv2(loanToken, IERC20(loanToken).balanceOf(address(this)), address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
        /////////////////////////////////////////////////////
        repayFlashLoan(loanToken, iToken, loanAmount);
        return bytes("1");
    }

    function executeOperation(address loanToken, address iToken, uint256 loanAmount) external returns (bytes memory success) {
        emit ExecuteOperation(loanToken, iToken, loanAmount);
        emit BalanceOf(IERC20(USDC).balanceOf(address(this)), "USDC");
        emit BalanceOf(IERC20(loanToken).balanceOf(address(this)), "loan");

        ERC20(USDC).approve(address(KYBER_PROXY), uint(-1));
        ERC20(loanToken).approve(address(KYBER_PROXY), uint(-1));
        uint256 minRate;
        uint256 amount = loanAmount * 10**18;

        (, minRate) = KYBER_PROXY.getExpectedRate(ERC20(loanToken), ERC20(USDC), amount);
        uint256 destAmount = KYBER_PROXY.swapTokenToToken(ERC20(loanToken), amount, ERC20(USDC), minRate);

        amount = loanAmount * 10**6;
        (, minRate) = KYBER_PROXY.getExpectedRate(ERC20(USDC), ERC20(loanToken), amount);
        destAmount = KYBER_PROXY.swapTokenToToken(ERC20(USDC), amount, ERC20(loanToken), minRate);

        emit BalanceOf(IERC20(USDC).balanceOf(address(this)), "USDC");
        emit BalanceOf(IERC20(loanToken).balanceOf(address(this)), "loan");

        repayFlashLoan(loanToken, iToken, loanAmount* 10**18);
        return bytes("1");
    }

    function doStuffWithFlashLoan(address token, address iToken, uint256 amount) external onlyOwner {
        bytes memory result;
        emit BalanceOf(IERC20(token).balanceOf(address(this)), "token");
        result = initiateFlashLoanBzx(token, iToken, amount);
        emit BalanceOf(IERC20(token).balanceOf(address(this)), "token");
        if (hashCompareWithLengthCheck(bytes("1"), result)) {
            revert("failed executeOperation");
        }
    }

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

    function swapOnUniswapv2(address fromToken, uint256 fromAmount,address toToken) internal {
        IUniswapV2Router uniV2_routerinterface = IUniswapV2Router(uniswapV2_routerAddress);
        // if the fromAmount is 0, then it is for toFrom call,
        // so we just need token balance of this sc.
        if(fromAmount == 0){
          fromAmount = IERC20(fromToken).balanceOf(address(this));
        }

        IERC20(fromToken).approve(uniswapV2_routerAddress, uint256(-1));
        // strange, this fails for USDT, but works for USDC.
        IERC20(toToken).approve(uniswapV2_routerAddress, uint256(-1));

        address[] memory path = new address[](2);
          path[0] = address(fromToken);
          path[1] = address(toToken);

        uniV2_routerinterface.swapExactTokensForTokens(fromAmount, 1, path, address(this), block.timestamp);
        // send back the traded token to msg.sender.
        uint256 toTokenBal = IERC20(toToken).balanceOf(address(this));
        IERC20(toToken).transfer(msg.sender, toTokenBal);
        emit paramsLog(fromToken, fromAmount, toToken, toTokenBal);
    }


    event ExecuteOperation(
        address loanToken,
        address iToken,
        uint256 loanAmount
    );

    event BalanceOf(uint256 balance, string  name);
}
