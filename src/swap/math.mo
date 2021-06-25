import Float "mo:base/Float";

module {
    public func sqrt(x : Float) : Float {
	    var z : Float = 1.0;
	    while( true ) {
	    	let tmp = z - (z*z-x)/(2*z);
	    	if (tmp == z) {
	    		return z;
	    	};

            let diff = tmp - z;
            if ( diff > 0 and diff < 0.000000000001) {
               return z;
            };
            
            if (diff < 0 and diff > -0.000000000001) {
                return z;
            };

		    z := tmp;
	    };
	    return z;
    };
}   