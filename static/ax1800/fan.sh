#!/bin/sh
#
# fan.sh —— 按温度控制风扇转速（借用状态灯的引脚做 PWM）
#
# 安装：把本文件上传到路由器，进到它所在的目录，执行一次
#           sh fan.sh
# 装好后在路由器上随处可用 fs 命令：
#           fs            查看当前温度和风速
#           fs 70         手动固定风速 70%（0~100，0=停，100=满速）
#           fs auto       改回按温度自动控制
#           fs stop       停风扇
#           fs start      重新开
#           fs uninstall  卸载
# 以后改了本文件的参数，再执行一次 sh fan.sh 就重新生效。
#
# ================= 可以改的参数 =================
#
# 风扇接在哪个灯脚上（内核名字）
LED=/sys/class/leds/green:status
# 1 = 这个脚低电平时风扇转。接反了（低电平不转）就改成 0
FAN_LOW=1
# PWM 周期，单位毫秒。调小更细腻，调大更稳
PERIOD_MS=50
# 每隔几秒测一次温度
INTERVAL=5
# 降档回差（摄氏度）：温度要掉到阈值以下这么多度才降档，防止临界点来回切
HYS=2
# 开机后等几秒才开始管风扇（0 = 开机立刻管）
BOOT_DELAY=60

# 温度 -> 风速：低于 40℃ 不转
temp_to_speed() {
	t=$(( $1 + ${2:-0} ))
	if   [ "$t" -ge 70 ]; then echo 100
	elif [ "$t" -ge 65 ]; then echo 80
	elif [ "$t" -ge 60 ]; then echo 50
	elif [ "$t" -ge 50 ]; then echo 30
	elif [ "$t" -ge 40 ]; then echo 20
	else echo 0
	fi
}

# ================= 参数到此为止 =================

DAEMON=/usr/bin/fs
MANUAL=/tmp/fan_speed
FORCE=/tmp/fan_force
SELF="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/$(basename "$0")"

# 取所有温区里最高的温度，单位摄氏度
read_temp() {
	awk 'BEGIN{m=-999999} { if ($1+0 > m) m=$1+0 } END { if (m == -999999) m=0; printf "%d", m/1000 }' /sys/class/thermal/thermal_zone*/temp 2>/dev/null
}

# 设置风速：set_pwm <0~100>
# 整个 PWM 都靠 timer 触发器做：
#   delay_on  = 引脚"高电平"的时间 = 风扇停的时间
#   delay_off = 引脚"低电平"的时间 = 风扇转的时间
# 风速 0   -> delay_on=周期, delay_off=0  -> 一直高电平 -> 风扇不转
# 风速 100 -> delay_on=0,   delay_off=周期 -> 一直低电平 -> 风扇满速
set_pwm() {
	if [ "$FAN_LOW" = 1 ]; then
		on=$(( (100 - $1) * PERIOD_MS / 100 ))
	else
		on=$(( $1 * PERIOD_MS / 100 ))
	fi
	if ! grep -q '\[timer\]' "$LED/trigger" 2>/dev/null; then
      echo timer > "$LED/trigger" || return 1
  fi
	echo "$on" > "$LED/delay_on"
	echo "$(( PERIOD_MS - on ))" > "$LED/delay_off"
}

# 一小段一小段地睡，这样收到停止信号能马上退出
nap() {
	i="$1"
	while [ "$i" -gt 0 ]; do sleep 1; i=$(( i - 1 )); done
}

# 后台主循环：一直盯着温度调风速
daemon() {
  if [ -f /tmp/fan_nodelay ]; then
      rm -f /tmp/fan_nodelay
  else
      nap "$BOOT_DELAY"
  fi
	cur=-1
	while :; do
		# 有人手动调过（fs N / fs auto），丢掉缓存重新算
		if [ -f "$FORCE" ]; then rm -f "$FORCE"; cur=-1; fi
		if [ -f "$MANUAL" ]; then
			spd="$(cat "$MANUAL" 2>/dev/null)"
      case "$spd" in
        ''|*[!0-9]*) spd=0 ;;
      esac
      [ "$spd" -gt 100 ] && spd=100
      why=手动
		else
			t="$(read_temp)"
			case "$t" in ''|*[!0-9-]*) t=0 ;; esac
			spd="$(temp_to_speed "$t")"
			[ "$spd" -lt "$cur" ] && spd="$(temp_to_speed "$t" "$HYS")"
			why="${t}℃"
		fi
		if [ "$spd" != "$cur" ]; then
			set_pwm "$spd"
			logger -t fan "风速 ${spd}% (${why})"
			cur="$spd"
		fi
		nap "$INTERVAL"
	done
}

show_status() {
	t="$(read_temp)"
	echo "温度     : ${t}℃"
	if [ -f "$MANUAL" ]; then
		echo "风速     : $(cat "$MANUAL")%  (手动固定)"
	else
		echo "风速     : $(temp_to_speed "$t")%  (按温度自动)"
	fi
	if [ "$FAN_LOW" = 1 ]; then
      echo "风扇引脚 : $LED   (高电平=停，低电平=满速)"
  else
      echo "风扇引脚 : $LED   (低电平=停，高电平=满速)"
  fi
	echo "PWM 周期 : ${PERIOD_MS}ms"
	if [ -x /etc/init.d/fs ]; then
		if /etc/init.d/fs running >/dev/null 2>&1; then
			echo "后台服务 : 运行中"
		else
			echo "后台服务 : 没在跑"
		fi
	fi
}

install() {
	echo "== 安装 fan.sh =="

	: > /tmp/fan_nodelay

	if [ "$SELF" != "$DAEMON" ]; then
		cp "$SELF" "$DAEMON" || { echo "复制到 $DAEMON 失败"; exit 1; }
	fi
	chmod 755 "$DAEMON"

	cat > /etc/init.d/fs <<'INIT'
#!/bin/sh /etc/rc.common
# 开机自动按温度控制风扇（真正的逻辑在 /usr/bin/fs 里）
START=97
STOP=14
USE_PROCD=1

start_service() {
	procd_open_instance
	procd_set_param command /usr/bin/fs daemon
	procd_set_param respawn 3600 5 5
	procd_set_param stdout 1
	procd_set_param stderr 1
	procd_close_instance
}

# 服务停掉以后把风扇关掉
service_stopped() {
	/usr/bin/fs off
}
INIT
	chmod 755 /etc/init.d/fs

	rm -f "$MANUAL" "$FORCE"
	/etc/init.d/fs enable
	/etc/init.d/fs restart >/dev/null 2>&1
	nap 2
	echo
	show_status
	echo
	echo "装好了，以后直接敲：fs 70 / fs auto / fs"
}

uninstall() {
	/etc/init.d/fs stop    2>/dev/null
	/etc/init.d/fs disable 2>/dev/null
	rm -f /etc/init.d/fs "$DAEMON" "$MANUAL" "$FORCE"
	set_pwm 0
	echo default-on > "$LED/trigger" 2>/dev/null
  echo "已卸载，风扇已停。LED 已恢复默认。"
}

usage() {
	cat <<'EOF'
fs            查看当前温度和风速
fs 70         手动固定风速 70%（0~100，0=停，100=满速）
fs auto       改回按温度自动控制
fs stop       停风扇
fs start      重新开
fs uninstall  卸载
EOF
}

case "$1" in
daemon)		daemon ;;

off)		rm -f "$MANUAL"; : > "$FORCE"; set_pwm 0 ;;

'')		if [ "$SELF" = "$DAEMON" ]; then show_status; else install; fi ;;

status)		show_status ;;

auto)		rm -f "$MANUAL"
        : > /tmp/fan_nodelay
        : > "$FORCE"
        if [ -x /etc/init.d/fs ] && ! /etc/init.d/fs running >/dev/null 2>&1; then
            /etc/init.d/fs start
            nap 2
        fi
        show_status
        ;;

start)		: > /tmp/fan_nodelay; /etc/init.d/fs start; nap 2; show_status ;;

stop)		/etc/init.d/fs stop; nap 1; echo "风扇已停。要重新开：fs start" ;;

uninstall)	uninstall ;;

-h|--help|help)	usage ;;

*)
	case "$1" in
	*[!0-9]*) echo "不认识的参数：$1"; usage; exit 1 ;;
	esac
	[ "$1" -gt 100 ] && { echo "风速最大 100"; exit 1; }
	echo "$1" > "$MANUAL"
	: > "$FORCE"
	set_pwm "$1"
	echo "风速已固定为 $1%（改回自动：fs auto）"
	;;
esac