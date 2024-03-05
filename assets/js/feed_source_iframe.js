const SERVER_EVENTS = {
  HIGHLIGHT: "phx:highlight",
  ENABLE_SELECT_MODE: "phx:enable_select_mode",
  DISABLE_SELECT_MODE: "phx:disable_select_mode",
};

const IFRAME_EVENTS = {
  ITEM_CLICK: "itemClicked",
  ENABLE_SELECT_MODE: "enableSelectMode",
  DISABLE_SELECT_MODE: "disableSelectMode",
  HIGHLIGHT_ITEM: "highlight",
};

const BROWSER_EVENTS = {
  ITEM_CLICK: "item_clicked",
  IFRAME_LOADED: "iframe_loaded",
};

const feedSourceIframeHook = {
  mounted() {
    const iframe = this.el;

    this.eventListeners = [
      {
        event: "message",
        handler: (event) => {
          if (event.data.type === IFRAME_EVENTS.ITEM_CLICK) {
            const { selector } = event.data;
            this.pushEventTo(`#${iframe.id}`, BROWSER_EVENTS.ITEM_CLICK, {
              selector,
            });
          }
        },
      },
      {
        event: SERVER_EVENTS.HIGHLIGHT,
        handler: handleHighlight(iframe),
      },
      {
        event: SERVER_EVENTS.ENABLE_SELECT_MODE,
        handler: handleSelectMode(IFRAME_EVENTS.ENABLE_SELECT_MODE, iframe),
      },
      {
        event: SERVER_EVENTS.DISABLE_SELECT_MODE,
        handler: handleSelectMode(IFRAME_EVENTS.DISABLE_SELECT_MODE, iframe),
      },
    ];

    this.eventListeners.forEach(({ event, handler }) => {
      window.addEventListener(event, handler);
    });

    iframe.contentWindow.addEventListener("load", (event) => {
      onIframeLoadHandler(iframe);
      this.pushEventTo(`#${iframe.id}`, BROWSER_EVENTS.IFRAME_LOADED);
    });
  },
  destroyed() {
    this.eventListeners.forEach(({ event, handler }) => {
      window.removeEventListener(event, handler);
    });
  },
};

const HIGHLIGHTED_HOVER_CLASS = "highlightedOnHover";

const onIframeLoadHandler = function (iframe) {
  const { contentDocument: iframeDocument, contentWindow: iframeWindow } =
    iframe;

  iframeDocument.addEventListener("click", (e) => {
    // Disable non-registered click events on iframe
    e.preventDefault();
    e.stopPropagation();
  });

  addIframeHighlightStyles(iframeDocument, HIGHLIGHTED_HOVER_CLASS);
  handleIframeMessages(iframeWindow, iframeDocument);
};

const handleHighlight = (iframe) => (e) => {
  sendMessageToIframe(
    {
      type: IFRAME_EVENTS.HIGHLIGHT_ITEM,
      selector: e.detail.selector,
      category: e.detail.category,
      backgroundColor: e.detail.background_color,
    },
    iframe
  );
};
const handleSelectMode = (iframeEvent, iframe) => (_) => {
  sendMessageToIframe(
    {
      type: iframeEvent,
    },
    iframe
  );
};

const addIframeHighlightStyles = (iframeDocument, hoverClassName) => {
  const style = iframeDocument.createElement("style");
  style.innerHTML = `
    .${hoverClassName} {
      cursor: pointer;
      background-color: rgba(255, 255, 0, 0.2) !important;
      }
    `;
  iframeDocument.head.appendChild(style);
};

const handleIframeMessages = (iframeWindow, iframeDocument) => {
  iframeWindow.addEventListener("message", (event) => {
    if (event.data.type === IFRAME_EVENTS.HIGHLIGHT_ITEM) {
      const { selector, category, backgroundColor } = event.data;

      if (category) {
        const existingNodes = iframeDocument.querySelectorAll(`.${category}`);
        existingNodes.forEach((el) => {
          el.classList.remove(category);
          el.style.backgroundColor = "";
        });

        if (selector) {
          iframeDocument.querySelectorAll(selector).forEach((el) => {
            el.style.backgroundColor = backgroundColor;
            el.classList.add(category);
          });
        }
      }
    }

    if (event.data.type === IFRAME_EVENTS.ENABLE_SELECT_MODE) {
      enableSelectMode(iframeDocument);
    }

    if (event.data.type === IFRAME_EVENTS.DISABLE_SELECT_MODE) {
      disableSelectMode(iframeDocument);
    }
  });
};

const enableSelectMode = (iframeDocument) => {
  iframeDocument.addEventListener("mouseover", onMouseOver);
  iframeDocument.addEventListener("mouseout", onMouseOut);
  iframeDocument.addEventListener("click", onClick);
};

const disableSelectMode = (iframeDocument) => {
  iframeDocument.removeEventListener("mouseover", onMouseOver);
  iframeDocument.removeEventListener("mouseout", onMouseOut);
  iframeDocument.removeEventListener("click", onClick);
};

const onMouseOver = (event) => {
  event.preventDefault();
  event.target.classList.add(HIGHLIGHTED_HOVER_CLASS);
};

const onMouseOut = (event) => {
  event.preventDefault();
  event.target.classList.remove(HIGHLIGHTED_HOVER_CLASS);
};

const onClick = (event) => {
  event.preventDefault();

  sendMessageToParent({
    type: IFRAME_EVENTS.ITEM_CLICK,
    selector: generateCSSSelector(event.target),
  });
};

const generateCSSSelector = (element) => {
  let selectorWithClassesParts = [];
  let tagSelectorParts = [];
  const documentElement = element.ownerDocument || element.documentElement;

  while (element.parentElement) {
    const tagName = element.tagName.toLowerCase();

    const className = Array.from(element.classList)
      .filter((c) => !c.includes(HIGHLIGHTED_HOVER_CLASS))
      .filter((c) => !c.includes(":")) // Removes pseudo-classes && Tailwind modifiers
      .join(".");

    selectorWithClassesParts.unshift(
      `${tagName}${className ? `.${className}` : ""}`
    );
    tagSelectorParts.unshift(tagName);

    element = element.parentElement;
  }

  const selectorWithClasses = selectorWithClassesParts.join(" > ");
  const tagSelector = tagSelectorParts.join(" > ");

  const selectorWithClassesMatches =
    documentElement.querySelectorAll(selectorWithClasses).length;

  if (selectorWithClassesMatches > 1) {
    // Selectors with classes get preference as they are more specific
    return selectorWithClasses;
  }

  const tagSelectorMatches =
    documentElement.querySelectorAll(tagSelector).length;

  if (tagSelectorMatches > 1) {
    return tagSelector;
  }

  return selectorWithClassesMatches > tagSelectorMatches
    ? selectorWithClasses
    : tagSelector;
};

const sendMessageToParent = (message) => {
  window.parent.postMessage(message, "*");
};

const sendMessageToIframe = (message, iframe) => {
  if (!iframe) return;
  const iframeWindow = iframe.contentWindow;
  if (!iframeWindow) return;

  iframeWindow.postMessage(message, "*");
};

export { feedSourceIframeHook };
