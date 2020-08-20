// Frida Kahlo's birthday (6 = July)
export const DEFAULT_ARGS = [2020, 6, 6];

const RealDate = Date;

const isMocked = val => Boolean(val.mock);

export const createFakeDateClass = ctorDefault => {
  const defaultDate = new RealDate(...ctorDefault);
  const defaultApplyDate = RealDate(...ctorDefault);

  const FakeDate = new Proxy(RealDate, {
    construct: (target, argArray) => {
      return argArray.length ? new RealDate(...argArray) : defaultDate;
    },
    apply: (target, thisArg, argArray) => {
      return argArray.length ? RealDate(...argArray) : defaultApplyDate;
    },
    // We want to overwrite the default 'now', but only if it's not already mocked
    get: (target, prop) => {
      if (prop === 'now' && !isMocked(target[prop])) {
        return () => defaultDate.getTime();
      }

      return target[prop];
    },
    // We need to be able to set props so that `jest.spyOn` will work.
    set: (target, prop, value) => {
      // eslint-disable-next-line no-param-reassign
      target[prop] = value;
      return true;
    },
  });

  return FakeDate;
};

export const useFakeDate = (...args) => {
  const FakeDate = createFakeDateClass(args.length ? args : DEFAULT_ARGS);
  global.Date = FakeDate;
};

export const useRealDate = () => {
  global.Date = RealDate;
};
