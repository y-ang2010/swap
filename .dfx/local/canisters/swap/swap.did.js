export default ({ IDL }) => {
  return IDL.Service({
    'greet' : IDL.Func([IDL.Text], [IDL.Text], []),
    'pairsInit' : IDL.Func([], [IDL.Text], []),
  });
};
export const init = ({ IDL }) => { return []; };