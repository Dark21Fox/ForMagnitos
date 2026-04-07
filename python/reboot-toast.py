"""
reboot-toast.py
Уведомляет пользователя о необходимости перезагрузки, если аптайм > 20 часов.

Логика по времени (скрипт должен запускаться по расписанию каждые ~30 мин):
  03:30–03:59  → Toast-уведомление с кнопками «Перезагрузить сейчас» / «Отложить на 30 мин»
  04:00–06:59  → Принудительный shutdown через 10 минут
  Иное время   → Ничего не делать
"""

import ctypes
import os
import time
import winreg
from datetime import datetime, timedelta

from windows_toasts import (
    InteractableWindowsToaster,
    Toast,
    ToastActivatedEventArgs,
    ToastButton,
    ToastDismissalReason,
    ToastDismissedEventArgs,
    ToastDuration,
)

# ── Константы ──────────────────────────────────────────────────────────────────

UPTIME_THRESHOLD_SEC = 72_000          # 20 часов
SHUTDOWN_DELAY_SEC   = 600             # 10 минут
SNOOZE_MINUTES       = 30             # Отложить на N минут

REG_PATH   = r"SOFTWARE\RebootMaintance\Settings"
APP_NAME   = "RebootMaintance"
GROUP_NAME = "RebootMaintance"


# ── Реестр ─────────────────────────────────────────────────────────────────────

def set_reg(name: str, value: str) -> bool:
    try:
        winreg.CreateKey(winreg.HKEY_CURRENT_USER, REG_PATH)
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_WRITE)
        winreg.SetValueEx(key, name, 0, winreg.REG_SZ, value)
        winreg.CloseKey(key)
        return True
    except OSError:
        return False


def get_reg(name: str) -> str | None:
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_READ)
        value, _ = winreg.QueryValueEx(key, name)
        winreg.CloseKey(key)
        return value
    except OSError:
        return None


# ── Аптайм ─────────────────────────────────────────────────────────────────────

def get_uptime_seconds() -> int:
    """Возвращает аптайм системы в секундах."""
    return ctypes.windll.kernel32.GetTickCount64() // 1000


# ── Уведомление ────────────────────────────────────────────────────────────────

def show_toast() -> str:
    """
    Показывает toast-уведомление и ожидает ответа пользователя.
    Возвращает: 'reboot' | 'delay' | 'canceled' | 'timeout'
    """
    result: list[str] = [None]  # список вместо nonlocal для совместимости

    toaster = InteractableWindowsToaster(APP_NAME)

    expiration = datetime.now() + timedelta(minutes=5)
    snooze_until = (datetime.now() + timedelta(minutes=SNOOZE_MINUTES)).strftime("%H:%M")

    toast = Toast(
        ["Внимание!"],
        group=GROUP_NAME,
        duration=ToastDuration.Long,
        expiration_time=expiration,
    )
    toast.text_fields = [
        "Необходимо выполнить перезагрузку ПК.",
        (
            "Сохраните все документы и завершите работу приложений. "
            f"Если отложить — следующее напоминание в {snooze_until}. "
            "Принудительная перезагрузка после 04:00."
        ),
    ]
    toast.AddAction(ToastButton("Перезагрузить сейчас", "reboot"))
    toast.AddAction(ToastButton(f"Отложить на {SNOOZE_MINUTES} мин", "delay"))

    def on_activated(args: ToastActivatedEventArgs):
        result[0] = args.arguments
        if args.arguments == "reboot":
            os.system("shutdown /t 0 /r /f")

    def on_dismissed(args: ToastDismissedEventArgs):
        if args.reason == ToastDismissalReason.USER_CANCELED:
            result[0] = "canceled"
        elif args.reason == ToastDismissalReason.TIMED_OUT:
            result[0] = "timeout"

    toast.on_activated = on_activated
    toast.on_dismissed = on_dismissed

    toaster.show_toast(toast)

    # Ждём реакции пользователя (максимум 6 минут — чуть больше expiration)
    deadline = time.time() + 360
    while result[0] is None and time.time() < deadline:
        time.sleep(1)

    return result[0] or "timeout"


# ── Проверка: не слишком ли рано повторять? ────────────────────────────────────

def snooze_still_active() -> bool:
    """
    Возвращает True, если пользователь нажал «Отложить» и время ещё не вышло.
    """
    action    = get_reg("action")
    saved_str = get_reg("time")

    if action != "delay" or saved_str is None:
        return False

    try:
        saved_time = datetime.fromtimestamp(float(saved_str))
    except (ValueError, OSError):
        return False

    return datetime.now() < saved_time + timedelta(minutes=SNOOZE_MINUTES)


# ── Принудительный shutdown ────────────────────────────────────────────────────

def schedule_forced_shutdown():
    reboot_at = (datetime.now() + timedelta(seconds=SHUTDOWN_DELAY_SEC)).strftime("%H:%M:%S")
    comment = (
        "Сохраните все документы и завершите работу приложений. "
        f"Принудительная перезагрузка будет произведена в {reboot_at}."
    )
    os.system(f'shutdown /t {SHUTDOWN_DELAY_SEC} /r /f /c "{comment}"')


# ── Главная логика ─────────────────────────────────────────────────────────────

def main():
    now    = datetime.now()
    hour   = now.hour
    minute = now.minute

    # Аптайм меньше порога — делать нечего
    if get_uptime_seconds() < UPTIME_THRESHOLD_SEC:
        return

    # Окно принудительной перезагрузки: 04:00–06:59
    if 4 <= hour <= 6:
        schedule_forced_shutdown()
        return

    # Окно уведомления: 03:30–03:59
    if hour == 3 and minute >= 30:
        if snooze_still_active():
            return

        action = show_toast()

        # Сохраняем результат в реестр
        set_reg("action", action)
        set_reg("time", str(time.time()))
        return


if __name__ == "__main__":
    main()
