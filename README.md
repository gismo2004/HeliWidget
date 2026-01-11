# HeliWidget
EdgeTX telemetry widget for RC helicopters running Rotorflight - real-time monitoring of headspeed, battery, temperatures, governor state, and comprehensive flight statistics with audio/haptic alerts

## Prerequisites
- **EdgeTX** Tested and used on 3.0 nightlies, but should work on 2.11+ too
- **Rotorflight** on flight controller :-)
- **RF2 Lua Script** with `rf2bg` background task configured
  -  Setup instructions: [Rotorflight Lua Scripts](https://github.com/rotorflight/rotorflight-lua-scripts)

## Minimum Telemetry Requirements
Designed for Rotorflight with the following minimum telemetry sensors configured:
- Main params (Vbat, Curr, Capa, Bat%, Cel#, Vcel, Vbec)
- ESC data (Tesc)
- Helicopter specifics (Hspd, Gov)
- Flight controller (ARM, ARMD, PID#, RTE#, Tmcu)

`set telemetry_sensors = 3,4,5,6,7,8,43,50,52,60,90,91,93,95,96,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0`

## Preview
<img width="480" height="272" alt="image" src="https://github.com/user-attachments/assets/d3c12d7f-61a1-4bfc-b158-0f157e5a1cf8" />
<img width="480" height="272" alt="image" src="https://github.com/user-attachments/assets/57338ada-7166-45f7-b91e-ea76303e206e" />

## Support & Disclaimer
- This is a personal hobby project shared freely with the community
- Provided as-is without warranty or guaranteed support
- Issues and pull requests are welcome but may not be addressed promptly
- **Use at your own risk** - always maintain visual line of sight and verify critical telemetry data
