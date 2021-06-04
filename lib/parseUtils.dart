num parseNum(String source) {
    num? integer = num.tryParse(source);
    if (integer == null) {
      integer = 0;
    }
    return integer;
}
