// blenertz copy
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// "SPDX-License-Identifier: Apache-2.0"

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
    function setLendingPoolImpl(address _pool) external;
    function getLendingPoolCore() external view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) external;
    function getLendingPoolConfigurator() external view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) external;
    function getLendingPoolDataProvider() external view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) external;
    function getLendingPoolParametersProvider() external view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) external;
    function getTokenDistributor() external view returns (address);
    function setTokenDistributor(address _tokenDistributor) external;
    function getFeeProvider() external view returns (address);
    function setFeeProviderImpl(address _feeProvider) external;
    function getLendingPoolLiquidationManager() external view returns (address);
    function setLendingPoolLiquidationManager(address _manager) external;
    function getLendingPoolManager() external view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) external;
    function getPriceOracle() external view returns (address);
    function setPriceOracle(address _priceOracle) external;
    function getLendingRateOracle() external view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) external;
}

interface ILendingPool {
  function addressesProvider () external view returns ( address );
  function deposit ( address _reserve, uint256 _amount, uint16 _referralCode ) external payable;
  function redeemUnderlying ( address _reserve, address _user, uint256 _amount ) external;
  function borrow ( address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode ) external;
  function repay ( address _reserve, uint256 _amount, address _onBehalfOf ) external payable;
  function swapBorrowRateMode ( address _reserve ) external;
  function rebalanceFixedBorrowRate ( address _reserve, address _user ) external;
  function setUserUseReserveAsCollateral ( address _reserve, bool _useAsCollateral ) external;
  function liquidationCall ( address _collateral, address _reserve, address _user, uint256 _purchaseAmount, bool _receiveAToken ) external payable;
  function flashLoan ( address _receiver, address _reserve, uint256 _amount, bytes calldata _params ) external;
  function getReserveConfigurationData ( address _reserve ) external view returns ( uint256 ltv, uint256 liquidationThreshold, uint256 liquidationDiscount, address interestRateStrategyAddress, bool usageAsCollateralEnabled, bool borrowingEnabled, bool fixedBorrowRateEnabled, bool isActive );
  function getReserveData ( address _reserve ) external view returns ( uint256 totalLiquidity, uint256 availableLiquidity, uint256 totalBorrowsFixed, uint256 totalBorrowsVariable, uint256 liquidityRate, uint256 variableBorrowRate, uint256 fixedBorrowRate, uint256 averageFixedBorrowRate, uint256 utilizationRate, uint256 liquidityIndex, uint256 variableBorrowIndex, address aTokenAddress, uint40 lastUpdateTimestamp );
  function getUserAccountData ( address _user ) external view returns (
    uint256 totalLiquidityETH,
    uint256 totalCollateralETH,
    uint256 totalBorrowsETH,
    uint256 totalFeesETH,
    uint256 availableBorrowsETH,
    uint256 currentLiquidationThreshold,
    uint256 ltv,
    uint256 healthFactor
  );
  function getUserReserveData ( address _reserve, address _user ) external view returns (
    uint256 currentATokenBalance,
    //uint256 currentUnderlyingBalance,
    uint256 currentBorrowBalance,
    uint256 principalBorrowBalance,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint256 liquidityRate,
    uint256 originationFee,
    uint256 variableBorrowIndex,
    uint256 lastUpdateTimestamp,
    bool usageAsCollateralEnabled
  );
  function getReserves () external view;
  event LiquidationCall(
        address indexed _collateral,
        address indexed _reserve,
        address indexed _user,
        uint256 _purchaseAmount,
        uint256 _liquidatedCollateralAmount,
        uint256 _accruedBorrowInterest,
        address _liquidator,
        bool _receiveAToken,
        uint256 _timestamp
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IKyber {
    function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);
    function swapTokenToEther(IERC20 token, uint tokenQty, uint minRate) external returns (uint);
    function swapTokenToToken(IERC20 src, uint srcAmount, IERC20 dest, uint minConversionRate) external returns (uint); //
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
}

interface IToken {
    function flashBorrow(uint256 borrowAmount, address borrower, address target, string calldata signature, bytes calldata data ) external payable returns (bytes memory);
}

interface IERC20 {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}


contract BZxFlashLoanerUNIKYBER is Ownable {

    IKyber public KYBER_PROXY = IKyber(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    address payable internal uniswapV2_routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 constant MAX_UINT = 2**256 - 1;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    IUniswapV2Router uniV2_routerinterface = IUniswapV2Router(uniswapV2_routerAddress);
    ILendingPool lendingPool;
    ILendingPoolAddressesProvider addressesProvider;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);



    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    function liquidateTarget(address collateral, address liquReserve, address user, uint256 liquAmount) public {
        bool getToken = false;
        lendingPool = ILendingPool(addressesProvider.getLendingPool());   // get lending pool contract address from the lending pool address provider interface

        if(isETH(IERC20(liquReserve))){
          emit LiquidationLog(lendingPool, collateral, liquReserve, user, liquAmount);
          lendingPool.liquidationCall.value(liquAmount)(collateral, liquReserve, user, liquAmount, getToken );
        } else {
          emit LiquidationLog(lendingPool, collateral, liquReserve, user, MAX_UINT);
          IERC20(liquReserve).approve(addressesProvider.getLendingPoolCore(), MAX_UINT);
          lendingPool.liquidationCall(collateral, liquReserve, user, MAX_UINT, getToken );
        }
    }




    function executeOperation(address loanToken, address iToken, uint256 loanAmount ) external returns (bytes memory success) {
        address collateralToken = address(USDC);

        emit BalanceOf(IERC20(loanToken).balanceOf(address(this)), "loan token at the beginning in executeOperation");

        IERC20(loanToken).approve(address(KYBER_PROXY), uint(-1));
        IERC20(collateralToken).approve(address(KYBER_PROXY), uint(-1));

        KYBER_PROXY.swapTokenToToken(IERC20(loanToken), loanAmount, IERC20(collateralToken), 0);
        emit BalanceOf(IERC20(loanToken).balanceOf(address(this)), "loan token after first swap in executeOperation");

        IERC20(loanToken).approve(uniswapV2_routerAddress, uint256(-1));
        IERC20(collateralToken).approve(uniswapV2_routerAddress, uint256(-1));

        swapOnUniswapv2(collateralToken, IERC20(collateralToken).balanceOf(address(this)), loanToken);
        emit BalanceOf(IERC20(loanToken).balanceOf(address(this)), "loan token after second swap in executeOperation");


        repayFlashLoan(loanToken, iToken, loanAmount);
        //emit BalanceOf(IERC20(loanToken).balanceOf(address(this)), "loan token after repayment in executeOperation");
        return bytes("1");
    }


    function priceCheck(address srcToken, address dstToken, uint256 amount) public returns (string memory success) {
        uint256 kyberRate;
        (, kyberRate) = KYBER_PROXY.getExpectedRate(IERC20(srcToken), IERC20(dstToken), amount);

        address[] memory path = new address[](2);
          path[0] = address(srcToken);
          path[1] = address(dstToken);
        uint[] memory uniswapRate;
        uniswapRate = uniV2_routerinterface.getAmountsOut(amount, path);

        if (kyberRate <= uniswapRate[1]) {
          emit PriceCheck(kyberRate, uniswapRate[1],  "kyber better");
          success = string("0");
          return success;
        }
        else {
          emit PriceCheck(uniswapRate[1], kyberRate,  "uni better");
          success =  string("1");
          return success;
        }
    }

    function withdraw(address token) public onlyOwner returns(bool) {
        if (address(token) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            uint256 rest = address(this).balance;
            msg.sender.transfer(rest);
        }
        else {
            IERC20 tokenToken = IERC20(token);
            uint256 tokenBalance = tokenToken.balanceOf(address(this));
            require(tokenToken.transfer(msg.sender, (tokenBalance)));
          }
        return true;
    }

    function doStuffWithFlashLoan(address token, address iToken, uint256 amount) external onlyOwner {
        bytes memory result;
        emit BalanceOf(IERC20(token).balanceOf(address(this)), "loan token before flash loan in doStuffWithFlashLoan");
        result = initiateFlashLoanBzx(token, iToken, amount);
        emit BalanceOf(IERC20(token).balanceOf(address(this)), "loan token after flash loan in doStuffWithFlashLoan");
        if (hashCompareWithLengthCheck(bytes("1"), result)) {
            revert("failed executeOperation");
        }
    }

    function swapEtherToToken(IERC20 token, address destAddress) public payable {
        uint minRate;
        (, minRate) = KYBER_PROXY.getExpectedRate(ETH_ADDRESS, token, msg.value);
        uint destAmount = KYBER_PROXY.swapEtherToToken.value(msg.value)(token, minRate);
        require(token.transfer(destAddress, destAmount));
    }

    function hashCompareWithLengthCheck(bytes memory a, bytes memory b) pure internal returns (bool) {
        if (a.length != b.length) {
            return false;
        } else {
            return keccak256(a) == keccak256(b);
        }
    }

    function repayFlashLoan(address loanToken, address iToken, uint256 loanAmount) internal {
      IERC20(loanToken).transfer(iToken, loanAmount);
    }

    function initiateFlashLoanBzx(address loanToken,address iToken,uint256 flashLoanAmount) internal returns (bytes memory success) {
        IToken iTokenContract = IToken(iToken);
        return iTokenContract.flashBorrow(flashLoanAmount,address(this),address(this),"",abi.encodeWithSignature("executeOperation(address,address,uint256)",loanToken,iToken,flashLoanAmount));
    }

    function swapOnUniswapv2(address fromToken, uint256 fromAmount, address toToken) internal {
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
        //IERC20(toToken).transfer(msg.sender, toTokenBal);
        emit paramsLog(fromToken, fromAmount, toToken, toTokenBal);
    }

    event ExecuteOperation(
        address loanToken,
        address iToken,
        uint256 loanAmount
    );

    event LiquidationLog(ILendingPool lendingPool, address collateral, address liquReserve, address user, uint256 liquAmount);
    event PriceCheck(uint256 rate1, uint256 rate2, string  name);
    event BalanceOf(uint256 balance, string  name);
    event paramsLog(
      address fromToken,
      uint256 fromTokenAmount,
      address tradeToken,
      uint256 tradeTokenAmount
    );
}
