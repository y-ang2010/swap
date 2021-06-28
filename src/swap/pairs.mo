import HashMap "mo:base/HashMap";
import Nat64 "mo:base/Nat64";
import OpRecord "./OpRecord";
import Types "./types";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Int64 "mo:base/Int64";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug"
//import Main "./main"


shared(msg) actor class Pairs(_token0 : Principal, _token1 : Principal, _feeTo : Principal, self : Principal) {
    type Address = Principal;
    //type OpRecordIn = OpRecord.OpRecordIn;

    let MINIMUM_LIQUIDITY : Nat64 = 1000;

    private stable var reserve0 : Nat64 = 0; // 储备量0
    private stable var reserve1 : Nat64 = 0; // 储备量1
    private stable var totalSupply : Nat64 = 0;

    private var balanceOf = HashMap.HashMap<Address, Nat64>(1, Principal.equal, Principal.hash);

    private stable var blockTimestampLast : Time.Time = 0;

    private stable var kLast : Nat64 = 0;                  // reserve0 * reserve1, as of immediately after the most recent liquidity event
    private stable var price0CumulativeLast : Nat64 = 0;   //价格0,最后累计值。在周边合约的预言机中有使用到
    private stable var price1CumulativeLast : Nat64 = 0;   //价格1,最后累计值。（https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol）
    
    private stable var token0 : Address = _token0;              // tA
    private stable var token1 : Address = _token1;              // tB
    private stable var feeTo  : Address = _feeTo;
    private stable var localCid : Principal = self;


    let t1 = Principal.toText( msg.caller);
    let t2 = Principal.toText(feeTo);

    Debug.print("pairs 1 " # t1);
    Debug.print("pairs 2" # t2);


    private func _update(
         balance0 : Nat64,           // 余额0
         balance1 : Nat64,           // 余额1
         _reserve0 : Nat64,       // 储备0
         _reserve1 : Nat64        // 储备1
        ) {
        // 校验余额0和余额1小等于uint112的最大数值，防止溢出
        //require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');

        // block.timestamp               区块时间戳
        // block.timestamp % 2**32       模上2**32得到余数为32位的uint32的数值
        //uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        var blockTimestamp : Time.Time = Time.now();
        // 计算时间流逝。当前时间戳 - 最近一次流动性事件的时间戳
        // （目的是为了校验更改的区块是过去时间已存在的）
        let timeElapsed = blockTimestamp - blockTimestampLast;        // overflow is desired

        // 满足条件 （ 间隔时间 > 0 && 储备量0,1 != 0 ）
        if (timeElapsed > 0 and _reserve0 != 0 and _reserve1 != 0) {
            // 最后累计的价格0 = UQ112(储备量1 / 储备量0) * 时间流逝
            // 最后累计的价格1 = UQ112(储备量0 / 储备量1) * 时间流逝
            // 计算得到的值在用于价格预言机中使用
            price0CumulativeLast += Nat64.div(reserve1, reserve0) * Nat64.fromIntWrap(timeElapsed);
            price1CumulativeLast += Nat64.div(reserve0, reserve1) * Nat64.fromIntWrap(timeElapsed);
        };

        // 将余额0和余额1分别赋值给储备量0和储备量1
        reserve0 := balance0;
        reserve1 := balance1;

        // 更新时间戳
        blockTimestampLast := blockTimestamp;
        // 触发同步事件
        //emit Sync(reserve0, reserve1);
    };

    private func _mint( to : Address, value : Nat64) {
        totalSupply := totalSupply + value;
       
        var newBalance = switch (balanceOf.get(to)) {
            case (?OldValue) {
                OldValue + value;
            };
            case (_) {
                value;
            };
        };
        balanceOf.put(to, newBalance);
        //balanceOf[to] := balanceOf[to].add(value);
        //OpRecordIn
        //emit Transfer(address(0), to, value);
        // record(address(0), to, value)
    };

    private func _burn( from : Address,  value : Nat64) {
        //balanceOf[from] := balanceOf[from].sub(value);
         var newBalance = switch (balanceOf.get(from)) {
            case (?OldValue) {
                OldValue - value;
            };
            case (_) {
                //throw Error.reject("burn err,no exist old value")
               0 - value;
            };
        };
        balanceOf.put(from, newBalance);
        totalSupply := totalSupply - value;
        //emit Transfer(from, address(0), value);
    };

    // private func _approve( owner : Address, spender : Address, value : Nat64)  {
    //     allowance[owner][spender] := value;
    //     //emit Approval(owner, spender, value);
    // };

    private func _transfer( from : Address, to : Address, value: Nat64)  {
        //balanceOf[from] := balanceOf[from].sub(value);
       
         var newBalance = switch (balanceOf.get(from)) {
            case (?OldValue) {
                OldValue - value;
            };
            case (_) {
                //throw Error.reject("burn err,no exist old value")
               0 - value;
            };
        };

        balanceOf.put(from, newBalance);
        //balanceOf[to] := balanceOf[to].add(value);
        
        var newToBalance = switch (balanceOf.get(to)) {
            case (?OldValue) {
                OldValue + value;
            };
            case (_) {
                //throw Error.reject("burn err,no exist old value")
               value;
            };
        };

        balanceOf.put(to, newToBalance);

        //emit Transfer(from, to, value);
    };

    public query func getReserves() : async ( Nat64, Nat64, Time.Time) {
        let _reserve0 = reserve0;                         // 储备量0
        let _reserve1 = reserve1;                         // 储备量1
        let _blockTimestampLast = blockTimestampLast;     // 时间戳
        return (_reserve0, _reserve1, _blockTimestampLast);
    };

    // public shared(msg) func initialize( _token0 : Address, _token1 : Address, _feeTo : Address)  {
    //     token0 := _token0;
    //     token1 := _token1;
    //     blockTimestampLast := Time.now();
    //     //feeTo := Principal.fromActor(LocalCanister);
    //     let eq = Principal.notEqual(_feeTo ,ZeroAddress);
    //     if eq {
    //         feeTo := _feeTo;
    //     };
    // };


    private func _mintFee(_reserve0 : Nat64,  _reserve1 : Nat64) : async Bool {
        //var  feeTo : Address = IUniswapV2Factory(factory).feeTo();

        // 定义个bool，如果feeTo地址为0，表示不收费
        let feeOn = true;
     
        let _kLast = kLast; // gas savings    恒定乘积做市商     x * y = k     上次收取费用的增长
        if (feeOn) {
            if (_kLast != 0) {
                // 以下算法在白皮书中有体现
                /**
                *    Sm = [ (sqrt(k2) - sqrt(k1)) / 5*sqrt(k2) + sqrt(k1) ] * S1
                */
                // S1表示在t1时间的流通股总数（totalSupply）
          
                let rootK : Float = Float.sqrt(Float.fromInt64(Int64.fromNat64(Nat64.mul(_reserve0,_reserve1)))); // k2
                let rootKLast : Float = Float.sqrt(Float.fromInt64(Int64.fromNat64(_kLast))); // k1

                var greater : Bool =  Float.greater( rootK, rootKLast );
                if  greater {
                    let diff =  Int64.toNat64(Float.toInt64(Float.sub(rootK, rootKLast)));
                    var numerator: Nat64 = Nat64.mul(totalSupply, diff);   // 分子
                    var denominator: Nat64 = Nat64.add(Int64.toNat64(Float.toInt64(Float.mul(rootK, 5))),Int64.toNat64(Float.toInt64(rootKLast)));           // 分母
                    var liquidity: Nat64 = numerator / denominator;

                    greater :=  Nat64.greater(liquidity, 0);
                    if  greater {
                        _mint(feeTo, liquidity);
                    };              // 如果计算得出的流动性 > 0，将流动性铸造给feeTo地址
                };
            };
        } else if (_kLast != 0) {
            kLast := 0;
        };

        return feeOn;
    };

    // 注入流通性币过程
    private  func mint(to : Address) : async (Nat64) {
        var liquidity : Nat64 = 0;
         // 从getReserves() 中获取t0 和 t1 的储备量，可以节省gas (view)
        // var aaa :(_reserve0 : Nat64, _reserve1 : Nat64,lasttime : Nat64) = ();
        //let aaa = getReserves();
       // let three  = getReserves();      // gas savings

        // 根据ERC20合约，可以获得token0和token1当前合约地址中所拥有的余额
        // let balance0 : Nat64 = IERC20(token0).balanceOf(address(this));
        // let balance1 : Nat64 = IERC20(token1).balanceOf(address(this));
        let balance0 : Nat64 = 10000000;
        let balance1 : Nat64 = 20000000;

        // amount0 = 余额0 - 储备0 ，表示本次带来的值
        let amount0 : Nat64 = Nat64.sub(balance0, reserve0);
        let amount1 : Nat64 = Nat64.sub(balance1, reserve1);

        // 计算流动性，根据是否开启收税给相应地址发送协议费用
        let feeOn : Bool = await _mintFee(reserve0, reserve1);

        //获取totalSupply,必须在此处定义，因为totalSupply可以在mintFee中更新
        let _totalSupply = totalSupply;                    // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            //流动性 = (数量0 * 数量1)的平方根 - 最小流动性1000
            let diff = Nat64.sub(Nat64.mul(amount0, amount1), MINIMUM_LIQUIDITY);
            let toFloat = Float.fromInt64( Int64.fromNat64(diff));
            liquidity := Int64.toNat64(Float.toInt64(Float.sqrt(toFloat)));
            //在总量为0的初始状态,永久锁定最低流动性(将它们发送到零地址，而不是发送到铸造者。)
           _mint(self, MINIMUM_LIQUIDITY);            // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            //流动性 = 最小值 (amount0 * _totalSupply / _reserve0) 和 (amount1 * _totalSupply / _reserve1)
            liquidity := Nat64.min(Nat64.div(Nat64.mul(amount0,_totalSupply) , reserve0), Nat64.div(Nat64.mul(amount1,_totalSupply), reserve1));
        };
        // 校验流动性 > 0
        //require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        //assert(liquidity > 0);
        //assert(0);
        // 铸造流动性发送给to地址
        _mint(to, liquidity);

        // 更新储备量
        _update(balance0, balance1, reserve0, reserve1);
        //如果铸造费开关为true, k值 = 储备0 * 储备1
        if (feeOn) { 
            kLast := Nat64.mul(reserve0,reserve1);
        }; // reserve0 and reserve1 are up-to-date
       
        // 触发铸造事件
        //emit Mint(msg.sender, amount0, amount1);
        //record(msg.sender, amount0, amount1);

        return liquidity
    };

    // 退出注入流通性过程
    public func burn(to : Address) : async (Nat64, Nat64) {
         // 获取储备量
        let (_reserve0, _reserve1,lastime) = await getReserves(); // gas savings

        let _token0 = token0;                                // gas savings
        let _token1 = token1;                                // gas savings

        // 获取当前调用者的地址在token0和token1中的余额
        // let balance0 = IERC20(_token0).balanceOf(address(this));
        // let balance1 = IERC20(_token1).balanceOf(address(this));

        let balance0 : Nat64 = 1000000;
        let balance1 : Nat64 = 2000000;

        // 获得当前地址的流动性（当前合约地址是不应该有余额的，因为在铸造配对合约过程中，最后是将计算到的流动性赋值给了传入的to地址）
        // 这个流动性的实际值是从路由合约的移除流动性方法中发送过来的（将调用者的流动性发送给pair合约）
        // removeLiquidity  ==》  IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        //let liquidity = balanceOf[address(this)];
        // 怎样获得本合约地址
        let liquidity = switch (balanceOf.get(self)){
            case (? value){
                value;
            };
        
            case (_) {
                // 程序到这里要panic
                //throw Error.reject("sss");
                let value : Nat64 = 0;
                //value;
            };
        };

        // 计算协议费用
        let feeOn : Bool = await _mintFee(_reserve0, _reserve1);

        // 节省gas，必须在此处定义，因为totalSupply可以在_mintFee中更新
        let _totalSupply = totalSupply;                      // gas savings, must be defined here since totalSupply can update in _mintFee

        // 使用余额确保按比例分配（取出的数值 = 我所拥有的流动性占比 * 总余额）
        let amount0 : Nat64 = Nat64.div(Nat64.mul(liquidity, balance0), _totalSupply);     // using balances ensures pro-rata distribution

        let amount1 : Nat64 = Nat64.div(Nat64.mul(liquidity, balance1), _totalSupply);     // using balances ensures pro-rata distribution

        // 校验取出余额都大于0
        //require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        // if !(amount0 > 0 && amount1 > 0) {
        //     return (0,0)
        // }
        assert(amount0 > 0 and amount1 > 0);
        // 使用erc20的销毁方法，为当前合约地址销毁流动性
        //let localCid : Principal = Principal.fromActor(Pairs);

        _burn(localCid, liquidity);

        // 调用安全发送方法，分别将t0取出的amount0和t1取出的amount1发送给to地址
        //_safeTransfer(_token0, to, amount0);
        //_safeTransfer(_token1, to, amount1);

        // 取出当前地址在合约上t0和t1的余额
        //balance0 := IERC20(_token0).balanceOf(address(this));
        //balance1 := IERC20(_token1).balanceOf(address(this));

        // let canister0 = actor(_token0): actor { getValue: () -> async Principal };
        // let balance = await canister0.getValue();


        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);

        // 如果开启了收取协议费用，则 kLast = x * y
        if (feeOn) {
            kLast := Nat64.mul(reserve0, reserve1); 
        }; // reserve0 and reserve1 are up-to-date

        return (balance0, balance1);

        // 触发销毁事件
        // msg.sender 此时应该为路由合约地址
        //emit Burn(msg.sender, amount0, amount1, to);
        //record(msg.sender, amount0, amount1, to)
    };

    // 交换币
    public func swap(
        amount0Out : Nat64,                  // 要取出的数额0
        amount1Out : Nat64,                  // 要取出的数额1
        to : Address,                       // 取出存放的地址
        //calldata : func (){} ,              // 存储的函数参数，只读。外部函数的参数（不包括返回参数）被强制为calldata
    ){
        // 校验取出数额0 或者 数额1其中一个大于 0
        //require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
      
        assert(amount0Out > 0 or amount1Out > 0);
        // 获取储备量0和储备量1
        let (_reserve0, _reserve1, lastime) = await getReserves(); // gas savings

        // 校验取出数额0小于储备量0  &&  取出数额1小于储备量1
        //require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');
        assert (amount0Out < _reserve0 and amount1Out < _reserve1);

        var balance0 : Nat64 = 0;
        var balance1 : Nat64 = 0;
       
        //{ // scope for _token{0,1}, avoids stack too deep errors
            let _token0 = token0;
            let _token1 = token1;
            // 校验to地址不能是t0和t1的地址
            //require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            assert(to != _token0 and to != _token1);

            // 确认取出数额大于0 ，就分别将t0和t1的数额安全发送到to地址
            //if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            //if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

            // 如果data长度大于0 ，调用to地址的接口
            // if (data.length > 0)
            //     // 闪电贷
            //     IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

            // 获取最新的t0和t1余额
            //balance0 := IERC20(_token0).balanceOf(address(this));
            //balance1 := IERC20(_token1).balanceOf(address(this));
        //}

        // amountIn = balance - (_reserve - amountOut)
        // 根据取出的储备量、原有储备量以及最新的余额，反推得到输入的数额
        var amount0In : Nat64 = 0;
        var amount1In : Nat64 = 0;
        if (balance0 > _reserve0 - amount0Out) {
            amount0In := balance0 - (_reserve0 - amount0Out);
        };

        if (balance1 > _reserve1 - amount1Out) {
            amount1In := balance1 - (_reserve1 - amount1Out);
        };
        // 确保任意一个输入数额大于0
        //require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        assert(amount0In > 0 or amount1In > 0);
        //{ // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            // 调整后的余额 = 最新余额 - 扣税金额 （相当于乘以997/1000）
        let balance0Adjusted = Nat64.sub(Nat64.mul(balance0, 1000), Nat64.mul(amount0In, 3));
        let balance1Adjusted = Nat64.sub(Nat64.mul(balance1, 1000), Nat64.mul(amount1In, 3));
            // 校验是否进行了扣税计算
            //require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        assert(Nat64.mul(balance0Adjusted,balance1Adjusted) >= Nat64.mul(Nat64.mul(_reserve0, _reserve1),1000 *100));
        //}

        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);
      
        // 记录交换事件
        //record(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to)
    };
} ;