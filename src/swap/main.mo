import pairs "./pairs";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug"

actor LocalCanister {
    public func greet(name : Text) : async Text {
        return "Hello, " # name # "!";
    };

    public func createPair(_token0 : Text, _token1 : Text, _feeTo : Text) : async Text {
    
        // 部署2个合约，并且获取它们的罐子id
        let token0  = Principal.fromText(_token0);
        let token1  = Principal.fromText(_token1);

        let self = Principal.fromActor(LocalCanister);

        var feeTo : Principal  = self;

        if (_feeTo != ""){
            feeTo := Principal.fromText(_feeTo);
        };

        let p = await pairs.Pairs(token0, token1, feeTo, self);
        //  p.initialize(token0, token1, feeTo);
    
        Debug.print(Principal.toText(token0));

        return "token0: " # Principal.toText(token1) # "\ntoken1:" # Principal.toText(token1) # "\nfeeTo:" # Principal.toText(feeTo) # "\ncreate success";
    };


    // 注入流动性
    public func mint(_token0 : Text, _token1 : Text, _feeTo : Text) : async Text {
    
        // 部署2个合约，并且获取它们的罐子id
        let token0  = Principal.fromText(_token0);
        let token1  = Principal.fromText(_token1);

        let self = Principal.fromActor(LocalCanister);

        var feeTo : Principal  = self;

        if (_feeTo != ""){
            feeTo := Principal.fromText(_feeTo);
        };

        let p = await pairs.Pairs(token0, token1, feeTo, self);
        //  p.initialize(token0, token1, feeTo);
    
        Debug.print(Principal.toText(token0));

        return "token0: " # Principal.toText(token1) # "\ntoken1:" # Principal.toText(token1) # "\nfeeTo:" # Principal.toText(feeTo) # "\ncreate success";
    };


    // A/B交换
    public func swap(_token0 : Text, _token1 : Text, _feeTo : Text) : async Text {
    
        // 部署2个合约，并且获取它们的罐子id
        let token0  = Principal.fromText(_token0);
        let token1  = Principal.fromText(_token1);

        let self = Principal.fromActor(LocalCanister);

        var feeTo : Principal  = self;

        if (_feeTo != ""){
            feeTo := Principal.fromText(_feeTo);
        };

        let p = await pairs.Pairs(token0, token1, feeTo, self);
        //  p.initialize(token0, token1, feeTo);
    
        Debug.print(Principal.toText(token0));

        return "token0: " # Principal.toText(token1) # "\ntoken1:" # Principal.toText(token1) # "\nfeeTo:" # Principal.toText(feeTo) # "\ncreate success";
    };


    // 退出 流动性提供
    public func burn(_token0 : Text, _token1 : Text, _feeTo : Text) : async Text {
    
        // 部署2个合约，并且获取它们的罐子id
        let token0  = Principal.fromText(_token0);
        let token1  = Principal.fromText(_token1);

        let self = Principal.fromActor(LocalCanister);

        var feeTo : Principal  = self;

        if (_feeTo != ""){
            feeTo := Principal.fromText(_feeTo);
        };

        let p = await pairs.Pairs(token0, token1, feeTo, self);
        //  p.initialize(token0, token1, feeTo);
    
        Debug.print(Principal.toText(token0));

        return "token0: " # Principal.toText(token1) # "\ntoken1:" # Principal.toText(token1) # "\nfeeTo:" # Principal.toText(feeTo) # "\ncreate success";
    };

};
