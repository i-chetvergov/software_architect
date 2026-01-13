document.addEventListener("DOMContentLoaded", () => {
    // Мягкая анимация карточек на главной
    const cards = document.querySelectorAll(".card");
    if (cards.length) {
      cards.forEach((el, i) => {
        el.style.opacity = 0;
        el.style.transform = "translateY(8px)";
        setTimeout(() => {
          el.style.transition = "opacity .18s ease, transform .18s ease";
          el.style.opacity = 1;
          el.style.transform = "translateY(0)";
        }, 60 + i * 70);
      });
    }
  });