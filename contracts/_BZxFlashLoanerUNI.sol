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

///////////////////////////////
interface IToken {
    function flashBorrow(uint256 borrowAmount, address borrower, address target, string calldata signature, bytes calldata data ) external payable returns (bytes memory);
}

contract BZxFlashLoanerUNI is Ownable {

  address payable internal uniswapV2_routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint constant MAX_UINT = 2**256 - 1;
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    event paramsLog(
      address fromToken,
      uint256 fromTokenAmount,
      address tradeToken,
      uint256 tradeTokenAmount
    );


    function executeOperation(address loanToken, address iToken, uint256 loanAmount ) external returns (bytes memory success) {
        emit BalanceOf(IERC20(loanToken).balanceOf(address(this)));
        emit ExecuteOperation(loanToken, iToken, loanAmount);
        /////////////////////////////////////////////////////
        swapOnUniswapv2(loanToken, IERC20(loanToken).balanceOf(address(this)), address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
        swapOnUniswapv2(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), IERC20(loanToken).balanceOf(address(this)), loanToken);
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

    function swapOnUniswapv2(
      address fromToken,
      uint256 fromAmount,
      address toToken
    )
      internal
    {
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

      uniV2_routerinterface.swapExactTokensForTokens(
        fromAmount, // amountIn
        1, // amountOutMin
        path,
        address(this), //msg.sender,//, single trade for USDT, need msg.sender.
        block.timestamp
      );

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

    event BalanceOf(uint256 balance);
}
