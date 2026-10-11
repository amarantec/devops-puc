// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.


let Hooks = {}

Hooks.PageTitle = {
  mounted() {
    this.handleEvent("update_title", ({ count }) => {
      if (count > 0) {
        document.title = `(${count}) Kgkm Chat`;
      } else {
        document.title = "Kgkm Chat";
      }
    })
  }
}

window.addEventListener("copy_to_clipboard", (e) => {
  if (e.detail && e.detail.text) {
    navigator.clipboard.writeText(e.detail.text);
  }
});
Hooks.MediaRecorder = {
  mounted() {
    let mediaRecorder;
    let audioChunks = [];
    let isRecording = false;

    this.el.addEventListener("click", async () => {
      try {
        if (!isRecording) {
          // Iniciar Gravação
          let stream = await navigator.mediaDevices.getUserMedia({ audio: true });
          mediaRecorder = new MediaRecorder(stream);
          audioChunks = [];

          mediaRecorder.ondataavailable = (e) => {
            if (e.data.size > 0) audioChunks.push(e.data);
          };

          mediaRecorder.onstop = () => {
            let audioBlob = new Blob(audioChunks, { type: 'audio/ogg; codecs=opus' });
            let reader = new FileReader();
            reader.readAsDataURL(audioBlob);
            reader.onloadend = () => {
              let base64data = reader.result;
              // Envia o áudio gravado em base64 de volta para o LiveView
              this.pushEvent("save_recorded_audio", { audio_data: base64data });
            };

            // Para as tracks de áudio liberando o microfone no navegador
            stream.getTracks().forEach(track => track.stop());
          };

          mediaRecorder.start();
          isRecording = true;
          this.el.classList.add("bg-red-500", "text-white", "animate-pulse");
          this.el.title = "Gravando... Clique para parar";
        } else {
          // Parar Gravação
          if (mediaRecorder) {
            mediaRecorder.stop();
          }
          isRecording = false;
          this.el.classList.remove("bg-red-500", "text-white", "animate-pulse");
          this.el.title = "Gravar Áudio";
        }
      } catch (err) {
        console.error("Erro ao acessar o microfone:", err);
        alert("Não foi possível acessar o microfone. Verifique as permissões do navegador.");
      }
    });
  }
}

Hooks.CameraCapture = {
  mounted() {
    let videoEl = this.el.querySelector("#video-preview") || this.el.querySelector("video");
    let canvasEl = this.el.querySelector("#camera-canvas");
    let captureBtn = document.getElementById("capture-photo-btn");
    let mediaStream = null;

    // Inicializa a câmera assim que o modal abre
    navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      .then(stream => {
        mediaStream = stream;
        if (videoEl) {
          videoEl.srcObject = stream;
        }
      })
      .catch(err => {
        console.error("Erro ao acessar a câmera:", err);
        alert("Não foi possível acessar a câmera do dispositivo.");
      });

    // Capturar Foto
    if (captureBtn) {
      captureBtn.addEventListener("click", () => {
        if (!videoEl) return;
        let context = canvasEl.getContext("2d");
        canvasEl.width = videoEl.videoWidth || 640;
        canvasEl.height = videoEl.videoHeight || 480;
        context.drawImage(videoEl, 0, 0, canvasEl.width, canvasEl.height);

        let base64data = canvasEl.toDataURL("image/jpeg", 0.9);

        // Para a stream da câmera
        if (mediaStream) {
          mediaStream.getTracks().forEach(track => track.stop());
        }

        // Envia a imagem capturada para o LiveView
        this.pushEvent("save_captured_image", { image_data: base64data });
      });
    }

    // Guarda a stream para poder desligar se o componente desmontar
    this.mediaStream = mediaStream;
  },
  destroyed() {
    if (this.mediaStream) {
      this.mediaStream.getTracks().forEach(track => track.stop());
    }
  }
}

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { hooks as colocatedHooks } from "phoenix-colocated/kgkm"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...colocatedHooks, ...Hooks },
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

