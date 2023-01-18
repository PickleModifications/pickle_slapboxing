var MaxHealth = 1000

var Bars = {
    home: `linear-gradient(to right, red 0%, red {PERCENT}%, rgb(127, 0, 0) {PERCENT}%)`,
    away: `linear-gradient(to left, rgb(0, 119, 255) 0%, rgb(0, 119, 255) {PERCENT}%, rgb(0, 64, 138) {PERCENT}%)`,
}

function SetHealth(team, health) {
    var health = Math.ceil(health)
    var percent = Math.ceil((health / MaxHealth) * 100)
    var style = Bars[team]
    style = style.replaceAll("{PERCENT}", percent)
    $(`.am-${team} > .bar`).css("background", style)
    $(`.am-${team} > div > .team-health`).html(`${health} HP`)
}

function ToggleUI(data) {
    if (data.value) {
        $("#app-main").css("display", "flex").hide().fadeIn(500);
        MaxHealth = data.maxHealth
        UpdateStats(data.stats)
    }
    else {
        $("#app-main").css("display", "flex").show().fadeOut(500);
    }
}

function UpdateStats(data) {
    SetHealth("home", data.home.health)
    SetHealth("away", data.away.health)
}

window.addEventListener("message", function(ev) {
    var event = ev.data
    if (event.toggleUI) {
        ToggleUI(event.value)
    }
    else if (event.updateStats) {
        UpdateStats(event.value)
    }
})