import { component$, useSignal, useStylesScoped$ } from "@builder.io/qwik";
import { _ } from "compiled-i18n";

export default component$(() => {
  useStylesScoped$(`
    div {
      background-color: red;
      padding: 1rem;
      border-radius: 0.5rem;
      margin: 1rem 0;
    }
    
    button {
      background: #007acc;
      color: white;
      border: none;
      padding: 0.5rem 1rem;
      margin: 0 0.5rem;
      border-radius: 0.25rem;
      cursor: pointer;
    }
    
    button:hover {
      background: #005f99;
    }
    
    .counter-display {
      margin: 0 1rem;
      font-weight: bold;
    }
  `);

  const count = useSignal(0);
  const userName = useSignal("John");

  return (
    <div>
      <h2>{_`welcome`}</h2>
      <p>{_`hello ${userName.value}`}</p>
      <div>
        <button type="button" onClick$={() => count.value--}>
          -
        </button>
        <span class="counter-display">
          {_`counter`}: {count.value}
        </span>
        <button type="button" onClick$={() => count.value++}>
          +
        </button>
      </div>
    </div>
  );
});
