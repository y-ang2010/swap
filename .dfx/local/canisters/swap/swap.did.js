export default ({ IDL }) => {
  return IDL.Service({ 'greet' : IDL.Func([IDL.Text], [IDL.Text], []) });
};
export const init = ({ IDL }) => { return []; };