<script lang="ts">
  import { getMatches } from "@tauri-apps/api/cli";
  import { invoke } from "@tauri-apps/api/tauri";
  import "../app.css";

  let url = "https://www.google.com";
  let isYoutube = false;
  let isWebsite = false;
  let isImage = false;
  let isVideo = false;
  function getYoutubeId(url: string) {
    const regExp =
      /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
    const match = url.match(regExp);

    return match && match[2].length === 11 ? match[2] : null;
  }
  let htmlContent = "";

  function parseUrl(value: string) {
    isYoutube = false;
    isWebsite = false;
    isImage = false;
    isVideo = false;
    if (value.match(/^(http|https):\/\//)) {
      isWebsite = true;
      const youtubeId = getYoutubeId(value);
      if (youtubeId) {
        isYoutube = true;
        value = youtubeId;
      }
    }

    if (value.match(/(png|jpg|jpeg|gif|bmp|svg)$/)) {
      isImage = true;
    } else if (value.match(/(mp4|webm|ogg)$/)) {
      isVideo = true;
    }
    url = value;
  }
  getMatches().then((matches) => {
    parseUrl(matches.args.url?.value as string);
  });
</script>

{#if isWebsite}
  {#if isYoutube}
    <div class="youtube-container">
      <iframe
        width="100%"
        height="100%"
        src="https://www.youtube.com/embed/{url}"
        title="YouTube video player"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        allowfullscreen
      />
    </div>
  {:else}
    <div>
      <iframe
        sandbox="allow-scripts allow-same-origin allow-popups allow-modals allow-forms"
        class="fullscreen"
        width="100%"
        height="100%"
        src={url}
        title="Website"
        frameborder="0"
      />
    </div>
  {/if}
{:else if isImage}
  <div class="fullscreen">
    <img src={url} alt="viewer" />
  </div>
{:else if isVideo}
  <div class="fullscreen">
    <video controls autoplay>
      <track kind="captions" />
      <source src={url} type="video/mp4" />
      Your browser does not support the video tag.
    </video>
  </div>
{/if}

<style>
  .fullscreen {
    display: block; /* iframes are inline by default */
    border: none; /* Reset default border */
    height: 100vh; /* Viewport-relative units */
    width: 100vw;
  }
  .youtube-container {
    overflow: hidden;
    /* 16:9 aspect ratio */
    /* padding-top: 56.25%; */
    /* position: relative; */
  }

  .youtube-container iframe {
    border: 0;
    height: 100%;
    left: 0;
    position: absolute;
    top: 0;
    width: 100%;
  }
</style>
