function convertToAnnual(rate) {
        var annualRate = Math.pow(1 + rate, 12) - 1;
        return annualRate;
}
