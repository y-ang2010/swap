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

        return "pairs token0: \n" # Principal.toText(token1) # "token1:" # Principal.toText(token1) # "feeTo:" # Principal.toText(feeTo) # "\n create success";
    };
};
