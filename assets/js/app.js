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

  // Tenta encontrar o botão que disparou o evento para dar o feedback visual
  let button = e.target.closest("button");
  if (button) {
    let originalHTML = button.innerHTML;
    // Altera o visual do botão temporariamente para indicar sucesso
    button.classList.add("bg-emerald-500", "text-white", "!border-emerald-500");
    button.classList.remove("bg-gray-200/70", "dark:bg-gray-700", "text-gray-700", "dark:text-gray-200");
    button.innerHTML = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-3.5 h-3.5">
    <path fill-rule="evenodd" d="M19.916 4.626a.75.75 0 0 1 .208 1.04l-9 13.5a.75.75 0 0 1-1.154.114l-6-6a.75.75 0 0 1 1.06-1.06l5.353 5.353 8.493-12.74a.75.75 0 0 1 1.04-.207Z" clip-rule="evenodd" />
    </svg> Copiado!
    `;

    // Restaura o botão original após 1.5 segundos
    setTimeout(() => {
      button.classList.remove("bg-emerald-500", "text-white", "!border-emerald-500");
      button.classList.add("bg-gray-200/70", "dark:bg-gray-700", "text-gray-700", "dark:text-gray-200");
      button.innerHTML = originalHTML;
    }, 1500);
  }
});

Hooks.MediaRecorder = {
  mounted() {
    let mediaRecorder;
    let audioChunks = [];
    let isRecording = false;

    this.el.addEventListener("click", async () => {
      // Se o usuário já negou antes, avisa sem floodar o navegador
      if (localStorage.getItem("mic_permission") === "denied") {
        alert("Permissão do microfone negada anteriormente. Altere nas configurações do navegador.");
        return;
      }
      
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

    if (localStorage.getItem("camera_permission") === "denied") {
      console.warn("Acesso à câmera negado anteriormente.");
      return;
    }

    navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      .then(stream => {
        localStorage.setItem("camera_permission", "granted");
        mediaStream = stream;
        this.mediaStream = stream;
        if (videoEl) {
          videoEl.srcObject = stream;
        }
      })
      .catch(err => {
        localStorage.setItem("camera_permission", "denied");
        console.error("Erro ao acessar a câmera:", err);
      });

    if (captureBtn) {
      captureBtn.addEventListener("click", () => {
        if (!videoEl || !canvasEl) return;
        let context = canvasEl.getContext("2d");
        canvasEl.width = videoEl.videoWidth || 640;
        canvasEl.height = videoEl.videoHeight || 480;
        context.drawImage(videoEl, 0, 0, canvasEl.width, canvasEl.height);

        let base64data = canvasEl.toDataURL("image/jpeg", 0.9);

        if (mediaStream) {
          mediaStream.getTracks().forEach(track => track.stop());
        }

        this.pushEvent("save_captured_image", { image_data: base64data });
      });
    }

    this.mediaStream = mediaStream;
  },
  destroyed() {
    // Garante que ao fechar o modal, a luz da câmera apaga imediatamente
    if (this.mediaStream) {
      this.mediaStream.getTracks().forEach(track => track.stop());
    }
  }
}

Hooks.ChatScroll = {
  mounted() {
    let container = this.el;
    let scrollBottomBtn = document.getElementById("scroll-to-bottom-btn");

    // Função de rolar até o fim
    let scrollToBottom = (smooth = false) => {
      container.scrollTo({
        top: container.scrollHeight,
        behavior: smooth ? "smooth" : "auto"
      });

      // Oculta o botão imediatamente ao descer
      if (scrollBottomBtn) {
        scrollBottomBtn.classList.add("hidden");
      }
    };

    // Rola para o fim assim que o chat monta
    scrollToBottom(false);
    setTimeout(() => scrollToBottom(false), 50); // Garante após o paint do DOM

    // Observa novas inserções no stream de mensagens
    this.handleEvent("scroll_to_bottom", () => {
      scrollToBottom(true);
    });

    // Controla a aparição do botão "descer para o fim" ao rolar para cima
    container.addEventListener("scroll", () => {
      let distanceFromBottom = container.scrollHeight - container.scrollTop - container.clientHeight;

      // Se o container não tiver scroll suficiente (chat vazio), nem mostra o botão
      if (container.scrollHeight <= container.clientHeight) {
        if (scrollBottomBtn) scrollBottomBtn.classList.add("hidden");
        return;
      }

      if (scrollBottomBtn) {
        if (distanceFromBottom > 300) {
          scrollBottomBtn.classList.remove("hidden");
          scrollBottomBtn.classList.add("flex");
        } else {
          scrollBottomBtn.classList.add("hidden");
          scrollBottomBtn.classList.remove("flex");
        }
      }
    });

    // Clique do botão flutuante para descer
    if (scrollBottomBtn) {
      scrollBottomBtn.addEventListener("click", () => {
        scrollToBottom(true);
      });
    }

    // Escuta evento global para focar/rolar até uma mensagem citada
    window.addEventListener("scroll_to_message", (e) => {
      let msgId = e.detail.msgId;
      let targetEl = document.getElementById(`message-${msgId}`);
      if (targetEl) {
        targetEl.scrollIntoView({ behavior: "smooth", block: "center" });
        // Efeito visual de destaque (piscar)
        targetEl.classList.add("ring-2", "ring-orange-500", "dark:ring-indigo-500", "transition-all", "duration-500");
        setTimeout(() => {
          targetEl.classList.remove("ring-2", "ring-orange-500", "dark:ring-indigo-500");
        }, 2000);
      }
    });
  },
  updated() {
    // Se o usuário estiver próximo ao final, rola automaticamente ao chegar nova mensagem
    let container = this.el;
    let distanceFromBottom = container.scrollHeight - container.scrollTop - container.clientHeight;
    if (distanceFromBottom < 150) {
      container.scrollTo({ top: container.scrollHeight, behavior: "smooth" });
    }
  }
}


window.addEventListener("phx:city-resolved", (e) => {
  if (e.detail && e.datail.city) {
    sessionStorage.setItem(
      "current_city",
      e.detail.city
    );
  }
});

Hooks.GetLocation = {
  mounted() {
    const hook = this;

    // 1. Ouve o evento vindo do LiveView quando o Nominatim resolve a cidade
    hook.handleEvent("city-resolved", ({ city }) => {
      localStorage.setItem("current_city", city);
    });

    // 2. Ouve solicitação manual para resetar via GPS
    hook.handleEvent("request-gps", () => {
      this.getGPSPosition();
    });

    // Se foi negado antes, nem tenta chamar o GPS para evitar loop
    if (localStorage.getItem("location_permission") === "denied") {
      return;
    }

    // 3. Verifica cache no localStorage
    const savedCity = localStorage.getItem("current_city");
    if (savedCity) {
      hook.pushEventTo(hook.el, "location-resolved", { city: savedCity });
      return;
    }

    // 4. Se não há cache, chama Geolocation do navegador
    this.getGPSPosition();
  },

  getGPSPosition() {
    const hook = this;
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          localStorage.setItem("location_permission", "granted"); // Salva sucesso
          hook.pushEventTo(hook.el, "location-resolved", {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude
          });
        },
        (error) => {
          localStorage.setItem("location_permission", "denied"); // Salva recusa
          console.error("Geolocation error:", error);
          hook.pushEventTo(hook.el, "location-failed", { reason: error.message });
        },
        { timeout: 10000, maximumAge: 600000 } // Cache do navegador por 10 min
      );
    } else {
      hook.pushEventTo(hook.el, "location-failed", { reason: "Não suportado" });
    }
  }
};


// Função auxiliar para converter a chave VAPID
function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

// Push Notificaition ativacao no browser
if ('serviceWorker' in navigator && 'PushManager' in window) {
  navigator.serviceWorker.ready.then(async (registration) => {
    const publicVapidKey = "BDiDjrZuXPHF1pJ3oUlhgNyaYPpeUa9qBhNnVDKvOiS8IPDi8zzRAxhf9t6ZA7QfKZoHwjw0KTE1ihGaSXB3ob4";

    // Converte a chave VAPID para Uint8Array
    const convertedKey = urlBase64ToUint8Array(publicVapidKey);

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: convertedKey
    });

    // Envia a subscription para o backend via fetch ou LiveView hook
    fetch('/api/push-subscriptions', {
      method: 'POST',
      body: JSON.stringify(subscription),
      headers: {
        'content-type': 'application/json',
        'x-csrf-token': document.querySelector("meta[name='csrf-token']").getAttribute("content")
      }
    });
  });
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

