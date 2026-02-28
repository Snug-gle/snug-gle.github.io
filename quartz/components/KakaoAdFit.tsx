import { QuartzComponent, QuartzComponentConstructor, QuartzComponentProps } from "./types"
import style from "./styles/adfit.scss"

const KakaoAdFit: QuartzComponent = ({ displayClass }: QuartzComponentProps) => {
  return (
    <div class={`kakao-adfit-wrapper ${displayClass ?? ""}`}>
      <ins
        class="kakao_ad_area"
        style="display:none;"
        data-ad-unit="DAN-uxo0G42dNJSfKyCj"
        data-ad-width="250"
        data-ad-height="250"
      ></ins>
    </div>
  )
}

KakaoAdFit.css = style

KakaoAdFit.afterDOMLoaded = `
  (function() {
    if (document.getElementById('kakao-adfit-script')) return;
    var script = document.createElement('script');
    script.id = 'kakao-adfit-script';
    script.type = 'text/javascript';
    script.charset = 'utf-8';
    script.src = '//t1.daumcdn.net/kas/static/ba.min.js';
    script.async = true;
    document.body.appendChild(script);
  })();
`

export default (() => KakaoAdFit) satisfies QuartzComponentConstructor
