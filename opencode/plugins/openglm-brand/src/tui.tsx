import { Plugin } from "@opencode/plugin/tui"
import { createSignal, onCleanup, onMount, For } from "solid-js"
import { usePlugin } from "@opencode/plugin/tui"
import { FRAMES, FRAMES_SMALL, DELAY_MS } from "./frames"

// Baked brand animation. Not configurable by design (openglm mod).
// Terminal-friendly: pure text frames, works even in classic cmd.

function useFrameIndex() {
  const [i, setI] = createSignal(0)
  onMount(() => {
    const timer = setInterval(() => setI((v) => (v + 1) % FRAMES.length), DELAY_MS)
    onCleanup(() => clearInterval(timer))
  })
  return i
}

function BrandGif() {
  const context = usePlugin()
  const i = useFrameIndex()
  return (
    <box flexDirection="column" alignItems="center" justifyContent="center">
      <For each={FRAMES[i()].split("\n")}>
        {(line) => (
          <text fg={context.theme?.text?.action?.primary?.base ?? "#3ce873"}>
            {line}
          </text>
        )}
      </For>
      <text fg={context.theme?.text?.muted ?? "#434b45"}>openglm</text>
    </box>
  )
}

// ambient strip above the composer - the closest a terminal gets to a chat background
function BrandStrip() {
  const context = usePlugin()
  const i = useFrameIndex()
  return (
    <box flexDirection="column" alignItems="center">
      <For each={FRAMES_SMALL[i()].split("\n")}>
        {(line) => (
          <text fg={context.theme?.text?.muted ?? "#434b45"}>
            {line}
          </text>
        )}
      </For>
    </box>
  )
}

export default Plugin.define({
  id: "openglm.brand",
  setup(context) {
    let playing = false
    const play = (duration: number) => {
      if (playing) return
      playing = true
      context.ui.dialog.show(() => <BrandGif />, () => { playing = false })
      setTimeout(() => {
        try { context.ui.dialog.clear() } catch {}
      }, duration)
    }

    // startup splash
    play(3500)
    context.ui.toast.show({ message: "openglm brand: loaded", variant: "success", duration: 2500 })

    // live strip above the chat input (always on while chatting)
    context.ui.slot({
      prepend: "session.composer.top",
      render: () => <BrandStrip />,
    })

    // /gif - full replay anytime
    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "openglm.gif",
          title: "openglm brand animation",
          slash: { name: "gif" },
          palette: true,
          run: () => play(8000),
        },
      ],
    }))

    return () => {}
  },
})
