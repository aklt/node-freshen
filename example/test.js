function test() {
  console.warn('Fresh FOO', {
    a: [23, {
      a:[1,2,3],
      f: {
        aaaa: 12121
      }
    }
    ]
  });
}
setTimeout(test, 1000);
