import pairs "./pairs";
import Principal "mo:base/Principal";

actor {
    public func greet(name : Text) : async Text {
        return "Hello, " # name # "!";
    };

    public func pairsInit() : async Text {
        // 部署2个合约，并且获取它们的Address
        let token0  = Principal.fromText("1234500");
        let token1  = Principal.fromText("1234501");
        let feeTo   = Principal.fromText("1234502");
        //pairs.Pairs(token0, token1, feeTo);

        return "pairs token0:" ;//# token0.toText() # "token1:" # token1.toText() # "feeTo:" # feeTo.ToText() ;
    };
};
