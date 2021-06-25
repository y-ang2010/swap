import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Hash "mo:base/Hash"


module {
    public type Address = Text;

    public func AddressEq(x : Address, y : Address) : Bool {
        var  _x : Text = x;
        var _y : Text = y;

        return Text.equal(_x, _y);
    };

    public func AddressHash(a : Address) : Hash.Hash { 
        var _a : Text = a;
        return Text.hash(_a);
        
    };
}