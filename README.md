# HeliWidget
EdgeTX telemetry widget for RC helicopters running Rotorflight - real-time monitoring of headspeed, battery, temperatures, governor state, and comprehensive flight statistics with audio/haptic alerts

## Minimum Telemetry Requirements
Designed for Rotorflight 2.x firmware with the following minimum telemetry sensors configured:
- Main params (Vbat, Curr, Capa, Bat%, Cel#, Vcel, Vbec)
- ESC data (Tesc)
- Helicopter specifics (Hspd, Gov)
- Flight controller (ARM, ARMD, PID#, RTE#, Tmcu)
  
`set telemetry_sensors = 3,4,5,6,7,8,43,50,52,60,90,91,93,95,96,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0`

## Preview
<img width="480" height="272" alt="image" src="https://github.com/user-attachments/assets/d3c12d7f-61a1-4bfc-b158-0f157e5a1cf8" />
<img width="480" height="272" alt="image" src="https://github.com/user-attachments/assets/57338ada-7166-45f7-b91e-ea76303e206e" />
