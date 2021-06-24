import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory as swap_idl, canisterId as swap_id } from 'dfx-generated/swap';

const agent = new HttpAgent();
const swap = Actor.createActor(swap_idl, { agent, canisterId: swap_id });

document.getElementById("clickMeBtn").addEventListener("click", async () => {
  const name = document.getElementById("name").value.toString();
  const greeting = await swap.greet(name);

  document.getElementById("greeting").innerText = greeting;
});
