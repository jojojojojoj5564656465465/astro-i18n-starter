import { component$, useStylesScoped$ } from "@builder.io/qwik";


export default component$(() => {
  useStylesScoped$(`
        div {
        margin-top:50px;
        padding: 10px;
        display: inline-flex;
        background-color: limegreen;
            color: blue;}`);
  return <div>'HHIHJJKIII'</div>;
});
