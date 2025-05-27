// src/components/MyQwikComponent.tsx
import { component$, useTask$, useSignal } from "@builder.io/qwik";
import { _ } from "compiled-i18n";

export default component$(() => {


  const name = "John";
  const emoji = "👋";
  const greeting = _`Hello ${name} ${emoji}!`;

  return (
    <div>
      <h1>{greeting}</h1>
    </div>
  );
});
