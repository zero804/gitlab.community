// Frida Kahlo's birthday (6 = July)
export const DEFAULT_ARGS = [2020, 6, 6];

const RealDate = Date;

export const createFakeDateClass = ctorDefault => {
  const defaultDate = new RealDate(...ctorDefault);
  const defaultApplyDate = RealDate(...ctorDefault);

  const FakeDate = new Proxy(Date, {
    construct: (target, argArray) => {
      return argArray.length ? new RealDate(...argArray) : defaultDate;
    },
    apply: (target, thisArg, argArray) => {
      return argArray.length ? RealDate(...argArray) : defaultApplyDate;
    },
    get: (target, prop) => {
      if (prop === 'now') {
        return () => defaultDate.getTime();
      }

      return RealDate[prop];
    },
  });

  return FakeDate;
};

export const useFakeDate = (...args) => {
  const prevDate = global.Date;

  const FakeDate = createFakeDateClass(args.length ? args : DEFAULT_ARGS);
  global.Date = FakeDate;

  const dispose = () => {
    global.Date = prevDate;
  };

  return dispose;
};

export const useRealDate = () => {
  global.Date = RealDate;
};
