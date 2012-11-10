function npv (discount, payments) 
 {
        var sum = 0;
        for(var i = 0; i < payments.length; i++) 
        {
                sum += payments[i]/Math.pow((1+discount), i);
        }
        return sum;
}

