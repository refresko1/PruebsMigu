//+------------------------------------------------------------------+
//|                                              Holy_Grail_1.36.mq4 |
//|                           MQLrefresko---Mqlrefresko.blogspot.com |
//|                                         Mqlrefresko.blogspot.com |
//+------------------------------------------------------------------+


//TP_PARCIAL
// % del margin sacrificado
//ReopenAnticiclo
//+------------------------------------------------------------------+
//|                       VERSIONS                                   |
//+------------------------------------------------------------------+
/*
V755.2c3: Se crea la opcion para un cierre de ciclo completo relacionado a los botones y a el SL_Equity. la opcion permite un AutoStop, o un reinicio del mismo;
V755.2c4: Se  cambia la opcion de ponerlo en un estado reset, a eliminar el Expert cuando se activa ese AUTOSTOP
V755.2c5: se corrije el calculo de el Equity_SL, para que se use independientemente de otras operaciones de la cuenta (actualmente cualquier otra operacion interviene en ese calculo)
V755.2c6: Se agrega boton de confirmacion (necesita la DLL "user32.dll" y las librerias "mt4gui2.mqh"  "WinUser32.mqh")
V755.2c7: *Se agrega una variable para determinar un tiempo Muerto del EstadoStandBy cuando se usa el autoStop.
          Para tener disponible las dos Opciones del AutoStop, de hace una lista despleglabe de 2 tipos de funcionamiento de ese parametro. una que lo retire, y lo otra que lo deje StandBy
          *se Pone el numero magico de manera externa
v755.2C8:Se Ajusta la lectura de las medias, que estaba siendo mal interpretada en algunas ocasiones
V755.2c9: *Se elimina todo lo de la SD y del Segundo Set.
          *se agrega la opcion para trabajar  con las medias de 2 maneras, la primera en base al cruce y medias en orden y la segunda, solo con el Cruce Basico,sin orden

V755.2d0: Se agrega el modulo de horario para inhabilitar el funcionamiento del EA en las primeras horas del dia lunes y las ultimas horas del dia Viernes
          Junto a ello se  agregan 2 tipos de modalidad, 1 "Solo_Apagar_Nuevos_Trades" en la que  solo apaga el expert, y la otra "Apagar_Nuevos_trades_y_cerrar_Todo" 
          en la que ademas de apagar el expert,  cierra todas las ordenes   
v755.2d1:  se amplia la posibilidad de eleccion de los dias de inhabilitacion, de manera inicial, en la version anterior esta solo por defecto para el  lunes y el viernes
v755.2d2:  se Limpia un poco el code y se ponen comentarios externos.          
*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


#property copyright "MQLrefresko---Mqlrefresko.blogspot.com"
#property link      "Mqlrefresko.blogspot.com"
#property version   "3.1"
#property strict

#include <mt4gui2.mqh>
#include <WinUser32.mqh>
#import "user32.dll"
int GetAncestor(int,int);
#import


// Declare global variables Libreria Botones
int hwnd=0;
int loginBtn,exitBtn;
int moveUpBtn,moveRightBtn,moveDownBtn,moveLeftBtn;
int loginHeader,loginPanel;
int usernameTextField,passwordTextField;
int gUIXPosition,gUIYPosition;
int authenticationFail=0;

// User credentials (fill in the ones you want to use)
string password="12345";
char TypeClose=-1;
// END TEMA BUTTONSSSSS

string Comentario="Tik755";
//+------------------------------------------------------------------+
//|          VARIABLeS EXTERNAS                                      |
//+------------------------------------------------------------------+
enum Select_Bar_Trade_Holy
  {
   Candle0_Holy=0,
   Candle1_Holy=1,
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Enum_orders_Type_Reopen_Holy
  {
   Direct_H=0,
   Pending_H=1,
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum  Enum_ModoSL_H
  {
   Modo_one_Step=0,
   Modo_Step_Step=1
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Enum_Modo_AutoStop_Button
  {
   RestartEA_Button=0,
   RemoveEA_Button=1
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Enum_Modo_AutoStop_SLEquity
  {
   RestartEA_SLEquity=0,
   RemoveEA_SLEquity=1
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Enum_modo_Order_Cruce
  {
   Cruce_Con_orden=0,
   Cruce_Sin_Orden=1
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Enum_Modo_Horary_System
  {
   Solo_Apagar_Nuevos_Trades=0,
   Apagar_Nuevos_trades_y_cerrar_Todo=1
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

input string   HOURS_OFF_SET="*** SET HOURS in format 'HH:MM:SS' (hour of Broker) ***";
input ENUM_DAY_OF_WEEK Day_Start=SUNDAY;
input string   Hour_Start_After="3:10:00";
input ENUM_DAY_OF_WEEK Day_End=SATURDAY;
input string   Hour_End_After="22:00:00";
input  Enum_Modo_Horary_System System_Horary=Apagar_Nuevos_trades_y_cerrar_Todo;

extern string MA_INPUTS_HOLY1="*** HOLY MAs_INPUTS ***";
extern int Period_Slow_MA_HOLY=15;
extern int Shift_Slow_MA_Holy=0;
extern int Period_Middle_MA_HOLY=10;
extern int Shift_Middle_Ma_Holy=0;
extern int Period_Fast_MA_HOLY=5;
extern int Shift_Fast_Ma_Holy=0;
input Enum_modo_Order_Cruce Modo_Cruce=0;

extern string GENERAL_INPUTS_HOLY="*** HOLY GENERAL_INPUTS ***";
input Select_Bar_Trade_Holy CandleOperation_HOLY=Candle1_Holy;
extern bool     Allow_closing_with_opposite_crossover_Holy=true;        //Allow cierre con cruce opuesto
extern int      Bars_wait_Close_in_Crossover_Holy=1;                    // Velas espera para cerrar con cruce opuesto

extern short    Bars_Wait_Confirm_HOLY=3;                               // Barras espera para confirmar Apertura de Trades
input bool      Allow_Close_if_Trade_touch_Tp_SL=true;                  //Allow cierre de trades si operacion cierra por TP o SL
extern bool     Close_in_One_Direction_Holy=False;                      // Cierre en 1 sola direccion si se tocan SL o TPs (False == Ambas direccio)

input string    SET_TRADES_OPUESTOS="*** SET_TRADES_OPUESTOS ***";
extern double   Multiplier_Factor_Lots_holy=1.0;                        //Multiplicador Lots para trades opuestos.
extern double   MAX_Percent_Expose_Account_Holy=30;                     //%%% MAX_Percent_Expose_Account_Holy per trade
extern double   Pips_TP_Cycle_Double_Lots_holy=10;                      //Pips TP ciclo Multiplicado
input string    Comentarios_TradeS_Opuestos="Tik755";

extern string   SET_ORDERS="** SET_ORDERS **";
extern short    Max_Trades_Per_Cycle_HOLY=10;
extern double   Lots_Cycle1_HOLY=0.01;                                  //Lots Operacion inicial del ciclo
extern double   Pips_SL_HOLY_Cycle1=10;                                 // Pips SL Operacion Inicial del ciclo
extern double   Pips_TP_HOLY_Cycle1=10;                                 // Pips TP Operacion Inicial del ciclo
extern double   Pips_New_Order_HOLY=10;                                 // Pips distancia NUEVAS Ordenes del ciclo
extern double   Lots_Cycle2_HOLY=0.01;                                  //Lots Operaciones Siguientes del ciclo
extern double   Pips_SL_HOLY_Cycle2=10;                                 // Pips SL Operaciones Siguientes del ciclo
extern double   Pips_TP_HOLY_Cycle2=10;                                 // Pips TP Operaciones Siguientes del ciclo
input string    Comentarios_TradeS_Originales="Tik755";

extern string   CONFIG_REOPEN_HOLY="** HOLY CONFIG_REOPEN **";
extern double   Pips_Movement_ReOpen_holy=10;                                 //Pips que activan el reopen(Zero = OFF)
input Enum_orders_Type_Reopen_Holy Orders_Type_Reopen_Holy=Direct_H;          //Tipo de ordenes en el reopen
extern int      Pips_Distance_Pending_Holy=10;                                //Pips distancia de reopen pdte (solo con type "Pending H");
input bool      Reopen_Multiples_Trades_Holy=false;                           //Reopen cuando existen otros trades ¿? 
input string    Comentarios_TradeS_Reopen="Tik755";

extern string   CONFIG_TRAILING_HOLY="** HOLY CONFIG_TRAILING **";
input bool      Allow_Trailing_Holy=true;
extern double   Pips_Trailing_HOLY=10;
extern double   Pips_Distance_Activation_Trailing_HOLY=10;
extern bool     Trailing_Close_All_Holy=True;                                 //Cerrar todo un grupo si en trailing cierra una operacion?

extern string   CONFIG_EQUITY_HOLY="** CONFIG_EQUITY HOLY **";
extern double   EquityPar_HOLY_Money=100;
extern bool     Trailing_Equity_Par_HOLY=False;
extern double   Pips_Trailing_EquityPar_HOLY=10;                              //Pips_Trailing_EquityPar_HOLY (Zero=off)

extern string   HALF_PROFIT_SET="** HOLY Set Half Profit **";
extern double   Closing_percentage_Holy=50;                                   //Closing Percentage Holy(50%)
extern double   Activator_percentage_Holy=70;                                 //Activator Percentage Max Holy (70%)

extern string   Sets_ADX_Holy="** HOLY SET ADX **";
extern double   MinADX_Holy=1;
extern double   MaxADX_Holy=100;

extern string   MoneyManagementHOLLY="** SET MONEYMANAGEMENT  **";
extern bool     AllowMoneyManagement_Holy=false;
extern double   Initial_Deposit_Holy=5000;
extern double   Percent_Step_Holy=10;                                         //%Porcent_Step_Holy  
extern double   Lots_Increment_Holy=0.01;

extern string   TP_PARCIAL="** SET TP PARCIAL **";
extern bool     Allow_TP_PARCIAL_Holy=false;
input int       SpacesTP_Holy=3;
input int       Divisor_Lots_Holy=2;
input bool      Allow_play_SL_Holy=false;
input Enum_ModoSL_H Mode_SL_TP_Parcial_Holy=Modo_one_Step;
input int      Ubicacion_BreakEven_Holy=2;                                    //step BreakEven Holy(in Mode One Step only)

input string     SET_EQUITY_SL_Holy="***SET EQUITY SL***";
input bool       Allow_Equity_SL_Holy=False;
input double     Target_Equity_SL_Holy=100;
input bool      Allow_Auto_Stop_Restart_EquitySL=False;
input Enum_Modo_AutoStop_SLEquity Modo_AutoStop_SLEquity=RemoveEA_SLEquity;
input int        Velas_Mute_SLEquity=0;                                       //Velas en las que se apaga expert despues de EquitySL

input string   MANUAL_TRADE="*** SET MANUAL TRADE ***";
input bool     Allow_Manual_Trade=false;
input bool     Allow_Auto_Stop_Restart_ManualTRADE=False;
input Enum_Modo_AutoStop_Button Modo_AutoStop_Button=RemoveEA_Button;
input int      Velas_Mute_Button=0;                                            //Velas en las que se apaga expert despues de Press button

input string OTHERS_SETTINGS="***OTHER_SETTINGS***";
input int Magic=766372;//Numero Magico (Identificador)

                       // agregar comentarios separados 
//---------------------------
bool Logical_Direction;
//------------------------

double Mult=1;
double MediaRapidaHoly,MediaLentaHoly,MediaMediaHoly;
char   CruceEfectivo_HOLY=0;
char   TipoCruce_HOLY=0;
char   BuscaCompra_HOLY=0;
char   BuscaVenta_HOLY=0;

string PrefijoHOLY="H_G";
short  TicketHoly_B,TicketHoly_S,TicketHoly_BS,TicketHoly_SS,TicketHoly_BL,TicketHoly_SL,TicketHoly_TT;
datetime TiempoAviso_HOLY=0;

double SL_MIN_Compra_HOLY=0;
double TP_MAX_Compra_HOLY=0;
double SL_MAX_Venta_HOLY=0;
double TP_MIN_Venta_HOLY=0;

int LastTradeHOLY=0;

datetime TiempoHOLYInicioCiclo1COMPRAS=0;
datetime TiempoHOLYInicioCiclo1VENTAS=0;
double QuiebreEquityParHOLY=0;

int UltimoTicketCerrado=0;
double QuiebreCompraHoly=0;
double QuiebreVentaHoly=0;

char UltimoSet=0;
char UltimoSetInicio=0;
char TipoCruceRapidoHoly=0;

char ActivaGananciaMedia_H=0;

int ListaPendientes_H[];

color ClrIndiTF;
string TxtIndiTF="";
double Adx=0;
bool PermisoCierreWaitCandles=false;
datetime TimePermisoCierreWaitCandles=0;

int AA=0;
int BB=0;

datetime UltimoAutoStop_SLEQUITY=0,UltimoAutoStop_ManualTrade=0,InicioMute_Button=0,InicioMute_SLEquity=0;

string Comentarios_TradeS_Opuestos2,Comentarios_TradeS_Originales2,Comentarios_TradeS_Reopen2;

//configuracion TP_PArcial
int corte=8;

//Config horarios
MqlDateTime strLunes,strViernes;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Comentarios_TradeS_Opuestos2=Comentarios_TradeS_Opuestos;
   Comentarios_TradeS_Originales2=Comentarios_TradeS_Originales;
   Comentarios_TradeS_Reopen2=Comentarios_TradeS_Reopen;

   if(Digits==3 || Digits==5)Mult=10;
   if(Bars_Wait_Confirm_HOLY<0)Bars_Wait_Confirm_HOLY=0;
   if(Bars_wait_Close_in_Crossover_Holy<1)Bars_wait_Close_in_Crossover_Holy=0;
   if(Bars_wait_Close_in_Crossover_Holy>Bars_Wait_Confirm_HOLY)Bars_wait_Close_in_Crossover_Holy=Bars_Wait_Confirm_HOLY;
   MAX_Percent_Expose_Account_Holy=NormalizeDouble(MAX_Percent_Expose_Account_Holy,2);
   if(IsTesting())
     {
      Comentario="TE_TPP_HOLY_";//debe ser de  12 de largo
      corte=6;
     }

   if(!IsTesting() && Allow_Manual_Trade)ManageEvents();
   if(Allow_Manual_Trade && !IsTesting())
     {
      CREATEBUTTONS();
      hwnd=WindowHandle(Symbol(),Period());
      guiRemoveAll(hwnd);

      // Measures chart width and height and sets default GUI X/Y-positions to center of the chart
      gUIXPosition = ((int) ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0)/2)-90;
      gUIYPosition = ((int) ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0)/2)-85;
      UltimoAutoStop_ManualTrade=TimeCurrent();
     }
   UltimoAutoStop_SLEQUITY=TimeCurrent();

   InicioMute_Button=Time[(int)MathMax(Velas_Mute_Button,Velas_Mute_SLEquity)];
   InicioMute_SLEquity=Time[(int)MathMax(Velas_Mute_Button,Velas_Mute_SLEquity)];

   if(Comentarios_TradeS_Opuestos2=="")Comentarios_TradeS_Opuestos2=Comentario;
   if(Comentarios_TradeS_Originales2=="")Comentarios_TradeS_Originales2=Comentario;
   if(Comentarios_TradeS_Reopen2=="")Comentarios_TradeS_Reopen2=Comentario;

   if(StringLen(Comentarios_TradeS_Opuestos2)>12)Comentarios_TradeS_Opuestos2=StringSubstr(Comentarios_TradeS_Opuestos2,0,12);
   if(StringLen(Comentarios_TradeS_Originales2)>12)Comentarios_TradeS_Originales2=StringSubstr(Comentarios_TradeS_Originales2,0,12);
   if(StringLen(Comentarios_TradeS_Reopen2)>12)Comentarios_TradeS_Reopen2=StringSubstr(Comentarios_TradeS_Reopen2,0,12);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Comment("");
   ObjectDelete(0,"BoxIndiTF");
   ObjectDelete(0,"NowIndiTF");
   ObjectDelete(0,"CloseAllButton");
   ObjectDelete(0,"CloseBuyButton");
   ObjectDelete(0,"CloseSellButton");
   ObjectDelete(0,"InfoButton0");
   ObjectDelete(0,"InfoButton1");
   ObjectDelete(0,"InfoButton2");

   int GVTT=GlobalVariablesTotal();
   GVTT=GlobalVariablesTotal();

   for(int tg4=GVTT-1;tg4>=0;tg4--)
     {
      string NombreGlobalVariable4=GlobalVariableName(tg4);
      string Seminombre=StringSubstr(NombreGlobalVariable4,corte,12);
      if(Seminombre=="TE_TPP_HOLY_")
        {
         GlobalVariableDel(NombreGlobalVariable4);
        }
     }
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---            
   if(sparam=="CloseAllButton")
     {
      TypeClose=3;
      BuildInterface();
     }

   if(sparam=="CloseBuyButton")
     {
      TypeClose=0;
      BuildInterface();
     }

   if(sparam=="CloseSellButton")
     {
      TypeClose=1;
      BuildInterface();
     }
//---      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void start()
  {
   if(!IsTesting() && Allow_Manual_Trade)
     {
      if(guiGetWidth(hwnd,loginPanel)>0)
        {
         ManageEvents();
        }
     }
   int VelasConfirmacionMute=0;
   if(InicioMute_Button>=InicioMute_SLEquity)VelasConfirmacionMute=Velas_Mute_Button;
   if(InicioMute_SLEquity>InicioMute_Button)VelasConfirmacionMute=Velas_Mute_SLEquity;

   if(iBarShift(NULL,0,MathMax(InicioMute_Button,InicioMute_SLEquity),true)>=VelasConfirmacionMute)
     {
      bool PermisoEA_Horario=true;
      datetime TimeStart=StringToTime(Hour_Start_After);
      datetime TimeEnd=StringToTime(Hour_End_After);
      TimeToStruct(TimeStart,strLunes);
      TimeToStruct(TimeEnd,strViernes);
      if(DayOfWeek()<Day_Start || (DayOfWeek()==Day_Start && ((Hour()<strLunes.hour) || (Hour()==strLunes.hour && Minute()<strLunes.min)))) PermisoEA_Horario=False;
      if(DayOfWeek()>Day_End   || (DayOfWeek()==Day_End && ((Hour()>strViernes.hour) || (Hour()==strViernes.hour && Minute()>strViernes.min)))) PermisoEA_Horario=False;

      if(!PermisoEA_Horario)
        {
         Comment("INACTIVO");
         TipoCruce_HOLY=0;
         if(System_Horary==Apagar_Nuevos_trades_y_cerrar_Todo) CIERRE_ALL_HOLY(1,1,1);
        }

      if(PermisoEA_Horario || (!PermisoEA_Horario && System_Horary==Solo_Apagar_Nuevos_Trades))
        {
         if(Allow_Equity_SL_Holy) EQUITY_SL();
         if(Allow_Trailing_Holy) TRAILING_HOLY();
         BUSCARGANACIA_HOLY();
         if(Allow_Close_if_Trade_touch_Tp_SL)CONFIRMARCIERRE_TP_o_SL_HOLY();
         if(EquityPar_HOLY_Money>0)EQUITY_PAR_HOLY();
         if(Pips_Movement_ReOpen_holy>0)FIND_NEW_REOPEN_HOLY();
         if(Closing_percentage_Holy>0 && Activator_percentage_Holy>0)GANANCIA_MEDIA();
         if(Allow_TP_PARCIAL_Holy)TP_PARCIAL_PPAL();
        }

      if(PermisoEA_Horario)
        {
         Comment("ACTIVO");
         if(Period_Fast_MA_HOLY>=Period_Middle_MA_HOLY || Period_Fast_MA_HOLY>=Period_Slow_MA_HOLY)
           {
            Print("The Fast MA, Must be the smaller of the MAs, the EA no run!!!!");
            Comment("The Fast MA, Must be the smaller of the MAs, the EA no run!!!!");
            return;
           }

         Adx=iADX(NULL,0,14,0,0,CandleOperation_HOLY);
         MediaRapidaHoly=iMA(NULL,0,Period_Fast_MA_HOLY,Shift_Fast_Ma_Holy,1,0,CandleOperation_HOLY);
         MediaMediaHoly= iMA(NULL,0,Period_Middle_MA_HOLY,Shift_Middle_Ma_Holy,1,0,CandleOperation_HOLY);
         MediaLentaHoly= iMA(NULL,0,Period_Slow_MA_HOLY,Shift_Slow_MA_Holy,1,0,CandleOperation_HOLY);

         //-----------------------------------------------------------------------------

         if(Modo_Cruce==Cruce_Con_orden)
           {
            if(TipoCruce_HOLY==0)
              {
               if(MediaRapidaHoly<MediaMediaHoly && MediaRapidaHoly<MediaLentaHoly && MediaMediaHoly<MediaLentaHoly)
                 {
                  TipoCruce_HOLY=-1;
                 }

               if(MediaRapidaHoly>MediaMediaHoly && MediaRapidaHoly>MediaLentaHoly && MediaMediaHoly>MediaLentaHoly)
                 {
                  TipoCruce_HOLY=1;
                 }
              }

            if(TipoCruce_HOLY==1)
              {
               if(MediaRapidaHoly<MediaMediaHoly && MediaRapidaHoly<MediaLentaHoly && MediaMediaHoly<MediaLentaHoly)
                 {
                  TipoCruce_HOLY=-1;
                  CruceEfectivo_HOLY=-1;
                 }
              }

            if(TipoCruce_HOLY==-1)
              {
               if(MediaRapidaHoly>MediaMediaHoly && MediaRapidaHoly>MediaLentaHoly && MediaMediaHoly>MediaLentaHoly)
                 {
                  TipoCruce_HOLY=1;
                  CruceEfectivo_HOLY=1;
                 }
              }
           }

         if(Modo_Cruce==Cruce_Sin_Orden)
           {
            if(TipoCruce_HOLY==0)
              {
               if(MediaRapidaHoly<MediaMediaHoly && MediaRapidaHoly<MediaLentaHoly)
                 {
                  TipoCruce_HOLY=-1;
                 }

               if(MediaRapidaHoly>MediaMediaHoly && MediaRapidaHoly>MediaLentaHoly)
                 {
                  TipoCruce_HOLY=1;
                 }
              }

            if(TipoCruce_HOLY==1)
              {
               if(MediaRapidaHoly<MediaMediaHoly && MediaRapidaHoly<MediaLentaHoly)
                 {
                  TipoCruce_HOLY=-1;
                  CruceEfectivo_HOLY=-1;
                 }
              }

            if(TipoCruce_HOLY==-1)
              {
               if(MediaRapidaHoly>MediaMediaHoly && MediaRapidaHoly>MediaLentaHoly)
                 {
                  TipoCruce_HOLY=1;
                  CruceEfectivo_HOLY=1;
                 }
              }
           }

         if(CruceEfectivo_HOLY!=0)
           {
            if(Time[0]!=TimePermisoCierreWaitCandles)
              {
               TimePermisoCierreWaitCandles=Time[0];
               PermisoCierreWaitCandles=True;
              }

            if(CruceEfectivo_HOLY==1)
              {
               BuscaCompra_HOLY=1;
               BuscaVenta_HOLY=0;
               TiempoAviso_HOLY=TimeCurrent();
              }

            if(CruceEfectivo_HOLY==-1)
              {
               BuscaCompra_HOLY=0;
               BuscaVenta_HOLY=1;
               TiempoAviso_HOLY=TimeCurrent();
              }
           }

         ///////////////// VELAS DE ESPERA CON CRUCE PARA CERRAR OPERACIONES
         if(TiempoAviso_HOLY!=0 && iBarShift(NULL,0,TiempoAviso_HOLY,true)==Bars_wait_Close_in_Crossover_Holy)
           {
            if(PermisoCierreWaitCandles)
              {
               if(Allow_closing_with_opposite_crossover_Holy) {CIERRE_ALL_HOLY(1,1,1);Print("2Cierre por cruce de medias con espera");}
               PermisoCierreWaitCandles=False;
              }
           }

         ///////////////// VELAS DE ESPERA CON CRUCE PARA ENTRAR AL MERCADO
         //  Print("Tiempo Av ",TiempoAviso_HOLY,"  Barras sh ",iBarShift(NULL,0,TiempoAviso_HOLY,true));
         if(TiempoAviso_HOLY!=0 && iBarShift(NULL,0,TiempoAviso_HOLY,true)==Bars_Wait_Confirm_HOLY)
           {
            double NewLots=NormalizeDouble(Lots_Cycle1_HOLY*Multiplier_Factor_Lots_holy,2);
            if(NewLots>MAXLOTS())NewLots=MAXLOTS();
            if(NewLots>MarketInfo(NULL,MODE_MAXLOT))NewLots=MarketInfo(NULL,MODE_MAXLOT);
            if(NewLots<MarketInfo(NULL,MODE_MINLOT))NewLots=MarketInfo(NULL,MODE_MINLOT);

            CalculateOrders_HOLY();

            if(BuscaCompra_HOLY>0 && TicketHoly_B==0 && TicketHoly_S==0 && Adx>MinADX_Holy && Adx<=MaxADX_Holy)
              {
               TRADE_DIRECTA_HOLY(Lots_Cycle1_HOLY,0,Pips_SL_HOLY_Cycle1*Mult,Pips_TP_HOLY_Cycle1*Mult,"H_G",Comentarios_TradeS_Originales2);
               TiempoHOLYInicioCiclo1COMPRAS=TimeCurrent();
               // AA+=1;
               Print("TRADE 9   ");
              }

            if(BuscaCompra_HOLY>0 && TicketHoly_B==0 && TicketHoly_S>0 && Adx>MinADX_Holy && Adx<=MaxADX_Holy)
              {
               TRADE_DIRECTA_HOLY(NewLots,0,Pips_SL_HOLY_Cycle1*Mult,Pips_TP_Cycle_Double_Lots_holy*Mult,"H_G",Comentarios_TradeS_Opuestos2);
               TiempoHOLYInicioCiclo1COMPRAS=TimeCurrent();
               //AA+=1;
               Print("TRADE 10   ");
              }

            //-----------------------
            if(BuscaVenta_HOLY>0 && TicketHoly_S==0 && TicketHoly_B==0 && Adx>MinADX_Holy && Adx<=MaxADX_Holy)
              {
               TRADE_DIRECTA_HOLY(Lots_Cycle1_HOLY,1,Pips_SL_HOLY_Cycle1*Mult,Pips_TP_HOLY_Cycle1*Mult,"H_G",Comentarios_TradeS_Originales2);
               TiempoHOLYInicioCiclo1VENTAS=TimeCurrent();
               //AA+=1;
               Print("TRADE 11    ");
              }
            if(BuscaVenta_HOLY>0 && TicketHoly_S==0 && TicketHoly_B>0 && Adx>MinADX_Holy && Adx<=MaxADX_Holy)
              {
               TRADE_DIRECTA_HOLY(NewLots,1,Pips_SL_HOLY_Cycle1*Mult,Pips_TP_Cycle_Double_Lots_holy*Mult,"H_G",Comentarios_TradeS_Opuestos2);
               TiempoHOLYInicioCiclo1VENTAS=TimeCurrent();
               //AA+=1;
               Print("TRADE 12   ");
              }
           }
         CruceEfectivo_HOLY=0;

        }
     }
  }
//+------------------------------------------------------------------+
//------------------CALCULAR ORDENES SD_MA----||
//                                            ||
//--------------------------------------------||
void CalculateOrders_HOLY()
  {
   TicketHoly_B=0; TicketHoly_S=0; TicketHoly_BS=0; TicketHoly_SS=0; TicketHoly_BL=0; TicketHoly_SL=0; TicketHoly_TT=0;
   double TotalCompras=0;
   double TotalVentas=0;

   for(int o=OrdersTotal()-1;o>=0;o--)
     {
      if(!OrderSelect(o,SELECT_BY_POS,MODE_TRADES))Print("No se pudo Seleccionar la orden en la parte del cod Calculatedor_Holy # 1");
      else
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
           {
            if(OrderType()==OP_BUY){TicketHoly_B+=1;TicketHoly_TT+=1;TotalCompras+=(OrderProfit()+OrderSwap()+OrderCommission());}
            if(OrderType()==OP_SELL){TicketHoly_S+=1;TicketHoly_TT+=1;TotalVentas+=(OrderProfit()+OrderSwap()+OrderCommission());}
            if(OrderType()==OP_BUYSTOP){TicketHoly_BS+=1;}
            if(OrderType()==OP_SELLSTOP){TicketHoly_SS+=1;}
            if(OrderType()==OP_BUYLIMIT){TicketHoly_BL+=1;}
            if(OrderType()==OP_SELLLIMIT){TicketHoly_SL+=1;}
           }
        }
     }

   if(Allow_Manual_Trade)
     {
      CREATEINFOBUTTONS(TotalVentas,"2",0);
      CREATEINFOBUTTONS(TotalCompras,"1",1);
      CREATEINFOBUTTONS(TotalCompras+TotalVentas,"0",2);
     }
  }
//+------------------------------------------------------------------+
////---------------------CIERRE ALLLLLLLL- HOLY------||
//                                                   ||
//---------------------------------------------------||
void CIERRE_ALL_HOLY(char CMP,char VNT,char PDT)
  {//poner 1 a la opcion que se quiere cerrar
   for(int ocat=OrdersTotal()-1;ocat>=0;ocat--)
     {
      if(!OrderSelect(ocat,SELECT_BY_POS,MODE_TRADES))Print("Error en la seleccion de Orden,CIERREALL HOLY 1");
      else
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
           {
            if(OrderType()==OP_BUY && CMP==1)
              {
               if(!OrderClose(OrderTicket(),OrderLots(),Bid,0,Gray))Print("Error en el cierre de Orden,CIERRE_ALL HOLY 2");
              }

            if(OrderType()==OP_SELL && VNT==1)
              {
               if(!OrderClose(OrderTicket(),OrderLots(),Ask,0,Gray))Print("Error en el cierre  de Orden,CIERRE_ALL HOLY 3");
              }

            if((OrderType()==OP_BUYSTOP) || (OrderType()==OP_SELLSTOP) || (OrderType()==OP_BUYLIMIT) || (OrderType()==OP_SELLLIMIT))
              {
               if(PDT==1)
                 {
                  if(!OrderDelete(OrderTicket()))Print("Error en la Eliminacion de Orden, CIERRE_ALL HOLY 4");
                 }
              }
           }
        }
     }
   if(CMP==1)
     {
      SL_MIN_Compra_HOLY=0;
      TP_MAX_Compra_HOLY=0;
      QuiebreCompraHoly=0;
     }

   if(VNT==1)
     {
      SL_MAX_Venta_HOLY=0;
      TP_MIN_Venta_HOLY=0;
      QuiebreVentaHoly=0;
     }

   if(CMP==1 && VNT==1)
     {
      QuiebreEquityParHOLY=0;
     }

   ActivaGananciaMedia_H=0;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|    COMPRA DIRECTA HOLY                                           |
//+------------------------------------------------------------------+
void TRADE_DIRECTA_HOLY(double LotsHOLY,short TypeTrade,double SL,double TP,string PreNombre,string Comentario2)
  {
   CalculateOrders_HOLY();
   if(TicketHoly_BS>0 || TicketHoly_SS>0)CIERRE_ALL_HOLY(0,0,1);

   double Prec_Trade_Dir=0,SL_Trade_Dire=0,TP_Trade_Dire=0;
   string PosNombre;
   color ColorTrade=clrNONE;

   if(TypeTrade==0)
     {
      Prec_Trade_Dir=Ask;
      SL_Trade_Dire=Prec_Trade_Dir-(SL*Point);
      TP_Trade_Dire=Prec_Trade_Dir+(TP*Point);
      PosNombre="_Com_";
      if(UltimoSet==1) ColorTrade=Blue;
      if(UltimoSet==2) ColorTrade=Magenta;
     }

   if(TypeTrade==1)
     {
      Prec_Trade_Dir=Bid;
      SL_Trade_Dire=Prec_Trade_Dir+(SL*Point);
      TP_Trade_Dire=Prec_Trade_Dir-(TP*Point);
      PosNombre="_Ven_";
      if(UltimoSet==1)  ColorTrade=Red;
      if(UltimoSet==2)  ColorTrade=Coral;
     }

   if(SL==0)SL_Trade_Dire=0;
   if(TP==0)TP_Trade_Dire=0;
   int TradeDIRECTo_HOLY=OrderSend(Symbol(),TypeTrade,LOTAJE_Holy(LotsHOLY),Prec_Trade_Dir,10,0,0,PreNombre+PosNombre+Comentario2,Magic,0,ColorTrade);
   if(!OrderSelect(TradeDIRECTo_HOLY,SELECT_BY_TICKET))Print("Error en la seleccion de Orden, TradeDirectoHOLY code1");
   if(SL_Trade_Dire>0 || TP_Trade_Dire>0)
     {
      if(!OrderModify(OrderTicket(),OrderOpenPrice(),SL_Trade_Dire,TP_Trade_Dire,0))
        {
         Print("Error Numero ",GetLastError()," al hacer la modificacion TradeDirectoHOLY del Ticket ",OrderTicket());
        }
     }
   if(TypeTrade==0)
     {
      if((SL_Trade_Dire!=0 && SL_Trade_Dire>SL_MIN_Compra_HOLY) || (SL_MIN_Compra_HOLY==0))SL_MIN_Compra_HOLY=SL_Trade_Dire;
      if((TP_Trade_Dire!=0 && TP_Trade_Dire<TP_MAX_Compra_HOLY) || (TP_MAX_Compra_HOLY==0))TP_MAX_Compra_HOLY=TP_Trade_Dire;
      // SL_MAX_Venta_HOLY=0;
      // TP_MIN_Venta_HOLY=0;
     }

   if(TypeTrade==1)
     {
      if((SL_Trade_Dire!=0 && SL_Trade_Dire<SL_MAX_Venta_HOLY) || (SL_MAX_Venta_HOLY==0))SL_MAX_Venta_HOLY=SL_Trade_Dire;
      if((TP_Trade_Dire!=0 && TP_Trade_Dire>TP_MIN_Venta_HOLY) || (TP_MIN_Venta_HOLY==0))TP_MIN_Venta_HOLY=TP_Trade_Dire;
      //SL_MIN_Compra_HOLY=0;
      //TP_MIN_Venta_HOLY=0;
     }
  }
//+------------------------------------------------------------------+
//|                     TRADE PENDIENTE                              |
//+------------------------------------------------------------------+
void TRADE_PENDIENTE_HOLY(double DistanciaPdte,double LotsHOLY,short TypeTrade,double SL,double TP,string PreNombre,string Comentario2)
  {
   double Prec_Trade_Pdte=0,SL_Trade_Pdte=0,TP_Trade_Pdte=0;
   string PosNombre;
   color ColorTrade=clrNONE;

   if(TypeTrade==2) //Buy Limit
     {
      Prec_Trade_Pdte=Ask-(DistanciaPdte*Point);
      SL_Trade_Pdte=Prec_Trade_Pdte-(SL*Point);
      TP_Trade_Pdte=Prec_Trade_Pdte+(TP*Point);
      PosNombre="_ComL_";
      if(UltimoSet==1)ColorTrade=Blue;
      if(UltimoSet==2)ColorTrade=Magenta;
     }

   if(TypeTrade==3) //SELL LIMIT
     {
      Prec_Trade_Pdte=Bid+(DistanciaPdte*Point);
      SL_Trade_Pdte=Prec_Trade_Pdte+(SL*Point);
      TP_Trade_Pdte=Prec_Trade_Pdte-(TP*Point);
      PosNombre="_VenL_";
      if(UltimoSet==1) ColorTrade=Red;
      if(UltimoSet==2)ColorTrade=Coral;
     }

   if(TypeTrade==4) //Buy STOP
     {
      Prec_Trade_Pdte=Ask+(DistanciaPdte*Point);
      SL_Trade_Pdte=Prec_Trade_Pdte-(SL*Point);
      TP_Trade_Pdte=Prec_Trade_Pdte+(TP*Point);
      PosNombre="_ComS_";
      if(UltimoSet==1)ColorTrade=Blue;
      if(UltimoSet==2)ColorTrade=Magenta;
     }

   if(TypeTrade==5) //SELL STOP
     {
      Prec_Trade_Pdte=Bid-(DistanciaPdte*Point);
      SL_Trade_Pdte=Prec_Trade_Pdte+(SL*Point);
      TP_Trade_Pdte=Prec_Trade_Pdte-(TP*Point);
      PosNombre="_VenS_";
      if(UltimoSet==1) ColorTrade=Red;
      if(UltimoSet==2)ColorTrade=Coral;
     }

   if(SL==0)SL_Trade_Pdte=0;
   if(TP==0)TP_Trade_Pdte=0;
   int TradePDte_HOLY=OrderSend(Symbol(),TypeTrade,LOTAJE_Holy(LotsHOLY),Prec_Trade_Pdte,10,SL_Trade_Pdte,TP_Trade_Pdte,PreNombre+PosNombre+Comentario2,Magic,0,ColorTrade);
/*
   if(!OrderSelect(TradePDte_HOLY,SELECT_BY_TICKET))Print("Error en la seleccion de Orden, TradePendienteHOLY code1");

   if(!OrderModify(OrderTicket(),OrderOpenPrice(),SL_Trade_Pdte,TP_Trade_Pdte,0))
       {
      Print("Error Numero ",GetLastError()," al hacer la modificacion TradePendienteHOLY del Ticket ",OrderTicket());
     }*/
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|              TRAILING HOLY                                       |
//+------------------------------------------------------------------+
void TRAILING_HOLY()
  {
   for(int oHOLY=OrdersTotal()-1;oHOLY>=0;oHOLY--)
     {
      if(!OrderSelect(oHOLY,SELECT_BY_POS,MODE_TRADES))Print("No se pudo Seleccionar la orden en la parte del code TrailingHOLY # 1");
      else
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
           {
            if(OrderType()==0)
              {
               if(((Bid-OrderOpenPrice()>((Pips_Distance_Activation_Trailing_HOLY+Pips_Trailing_HOLY)*Mult)*Point) && (Bid-OrderStopLoss()>(Pips_Trailing_HOLY*Mult)*Point))
                  || ((Bid-OrderOpenPrice()>((Pips_Distance_Activation_Trailing_HOLY+Pips_Trailing_HOLY)*Mult)*Point) && !OrderStopLoss()))
                 {
                  double SLT=NormalizeDouble(Bid-((Pips_Trailing_HOLY*Mult)*Point),Digits);
                  if(SLT!=OrderStopLoss() && SLT!=0)
                    {
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),SLT,OrderTakeProfit(),0))Print("No se puede modificar la Orden en el TrailingHOLY # 2 ",OrderStopLoss(),"  ",SLT);
                     else
                       {
                        if(Trailing_Close_All_Holy && SL_MIN_Compra_HOLY<SLT)SL_MIN_Compra_HOLY=SLT;
                       }
                    }
                 }
              }

            if(OrderType()==1)
              {
               if(((OrderOpenPrice()-Ask>((Pips_Distance_Activation_Trailing_HOLY+Pips_Trailing_HOLY)*Mult)*Point) && (OrderStopLoss()-Ask>(Pips_Trailing_HOLY*Mult)*Point))
                  || ((OrderOpenPrice()-Ask>((Pips_Distance_Activation_Trailing_HOLY+Pips_Trailing_HOLY)*Mult)*Point) && !OrderStopLoss()))
                 {
                  double SLTv=NormalizeDouble(Ask+((Pips_Trailing_HOLY*Mult)*Point),Digits);
                  if(SLTv!=OrderStopLoss() && SLTv!=0)
                    {
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),SLTv,OrderTakeProfit(),0))Print("No se puede modificar la Orden en el TrailingHOLY # 3 ",OrderStopLoss(),"  ",SLTv);
                     else
                       {
                        if(Trailing_Close_All_Holy && SL_MAX_Venta_HOLY>SLTv)SL_MAX_Venta_HOLY=SLTv;
                       }
                    }
                 }
              }
           }
        }
     }
  }
//---------------------Buscar ganancia HOLY-------||
//                                                   ||
//---------------------------------------------------||
void BUSCARGANACIA_HOLY()
  {
   double ProfitCompra=10000000;
   double ProfitVenta=10000000;
   datetime UltimaCompra=0;
   datetime UltimaVenta=0;
   int OrdenCompra=0;
   int OrdenVenta=0;

   CalculateOrders_HOLY();

   for(int busqGanancia=0;busqGanancia<OrdersTotal();busqGanancia++)
     {
      if(!OrderSelect(busqGanancia,SELECT_BY_POS,MODE_TRADES))Print("Error al  Seleccionar la orden, BuscarGanancia code 1");
      else
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
           {
            if(OrderType()==0)
              {
               if(OrderOpenTime()>UltimaCompra)
                 {
                  UltimaCompra=OrderOpenTime();
                  OrdenCompra=OrderTicket();
                 }
              }

            if(OrderType()==1)
              {
               if(OrderOpenTime()>UltimaVenta)
                 {
                  UltimaVenta=OrderOpenTime();
                  OrdenVenta=OrderTicket();
                 }
              }
           }
        }
     }

   if(OrdenCompra>0)
     {
      if(!OrderSelect(OrdenCompra,SELECT_BY_TICKET))Print("Error al seleccionar la ordenCompra, BuscarGanancia HOLY code 1");
      else
        {
         if(Ask-OrderOpenPrice()>=((Pips_New_Order_HOLY*Mult)*Point) && OrderCloseTime()==0)
           {
            if(TicketHoly_B<Max_Trades_Per_Cycle_HOLY)
              {
               double NewLots2=NormalizeDouble(Lots_Cycle2_HOLY*Multiplier_Factor_Lots_holy,2);
               if(NewLots2>MAXLOTS())NewLots2=MAXLOTS();
               if(NewLots2>MarketInfo(NULL,MODE_MAXLOT))NewLots2=MarketInfo(NULL,MODE_MAXLOT);
               if(NewLots2<MarketInfo(NULL,MODE_MINLOT))NewLots2=MarketInfo(NULL,MODE_MINLOT);

               if(TicketHoly_S==0){TRADE_DIRECTA_HOLY(Lots_Cycle2_HOLY,0,Pips_SL_HOLY_Cycle2*Mult,Pips_TP_HOLY_Cycle2*Mult,"H_G2",Comentarios_TradeS_Originales2);Print(TimeCurrent());}
               if(TicketHoly_S>0){TRADE_DIRECTA_HOLY(NewLots2,0,Pips_SL_HOLY_Cycle2*Mult,Pips_TP_Cycle_Double_Lots_holy*Mult,"H_G2",Comentarios_TradeS_Originales2);}
               return;
              }
           }
        }
     }

   if(OrdenVenta>0)
     {
      if(!OrderSelect(OrdenVenta,SELECT_BY_TICKET))Print("Error al seleccionar la OrdenVenta, BuscarGananciaHOLY code 2");
      else
        {
         if(OrderOpenPrice()-Bid>=((Pips_New_Order_HOLY*Mult)*Point) && OrderCloseTime()==0)
           {
            if(TicketHoly_S<Max_Trades_Per_Cycle_HOLY)
              {
               double NewLots3=NormalizeDouble(Lots_Cycle2_HOLY*Multiplier_Factor_Lots_holy,2);
               if(NewLots3>MAXLOTS())NewLots3=MAXLOTS();
               if(NewLots3>MarketInfo(NULL,MODE_MAXLOT))NewLots3=MarketInfo(NULL,MODE_MAXLOT);
               if(NewLots3<MarketInfo(NULL,MODE_MINLOT))NewLots3=MarketInfo(NULL,MODE_MINLOT);

               if(TicketHoly_B==0){ TRADE_DIRECTA_HOLY(Lots_Cycle2_HOLY,1,Pips_SL_HOLY_Cycle2*Mult,Pips_TP_HOLY_Cycle2*Mult,"H_G2",Comentarios_TradeS_Originales2);}
               if(TicketHoly_B>0) {TRADE_DIRECTA_HOLY(NewLots3,1,Pips_SL_HOLY_Cycle2*Mult,Pips_TP_Cycle_Double_Lots_holy*Mult,"H_G2",Comentarios_TradeS_Originales2);}
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//----------------ConfirmarCierres HOLY-------||
//                                              ||
//----------------------------------------------||
void CONFIRMARCIERRE_TP_o_SL_HOLY()
  {
   int TickHistoryNew=0;
   datetime TiempoTickHistoryNew=0;
   char TypeOrdenHistoryNew=-1;

   for(int busqCcSL_tp=OrdersHistoryTotal()-1;busqCcSL_tp>=0;busqCcSL_tp--)
     {
      if(!OrderSelect(busqCcSL_tp,SELECT_BY_POS,MODE_HISTORY))Print("error en la seleccion de Orden Historica ConfirmaCierreTP_SL_HOLY code 0  ",OrdersHistoryTotal(),"    ",busqCcSL_tp);
      else
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
           {
            if(OrderCloseTime()>TiempoTickHistoryNew)
              {
               TiempoTickHistoryNew=OrderCloseTime();
               TickHistoryNew=OrderTicket();
               TypeOrdenHistoryNew=(char)OrderType();
               if(OrderProfit()>0 && OrderOpenTime()>MathMax(UltimoAutoStop_SLEQUITY,UltimoAutoStop_ManualTrade))
                 {
                  UltimoTicketCerrado=OrderTicket();
                 }
              }
           }
        }
     }

   if(TickHistoryNew>0 && TypeOrdenHistoryNew==0)
     {
      if((Bid>=TP_MAX_Compra_HOLY && TP_MAX_Compra_HOLY>0) || (Bid<=SL_MIN_Compra_HOLY && SL_MIN_Compra_HOLY>0))
        {
         for(int ocsHOLY=OrdersHistoryTotal()-1;ocsHOLY>=0;ocsHOLY--)
           {
            if(!OrderSelect(ocsHOLY,SELECT_BY_POS,MODE_HISTORY))Print("Error en la seleccion de Orden, ConfirmaCierreTP_SL_HOLY Code 2");
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
              {
               //Print ("OHT ",OrdersHistoryTotal(),"  OT ", OrderType(),"  OCT ",OrderCloseTime()," Tiempoi ",TiempoInicioCiclo1,"  OCP ",OrderClosePrice(), "  TPMXC ",TP_MAX_C, "  SLMinC ",SL_MIN_C, "  Bid ",Bid);
               if((OrderType()==0 && OrderCloseTime()>=TiempoHOLYInicioCiclo1COMPRAS && OrderClosePrice()>=TP_MAX_Compra_HOLY && TP_MAX_Compra_HOLY>0) ||
                  (OrderType()==0 && OrderCloseTime()>=TiempoHOLYInicioCiclo1COMPRAS && OrderClosePrice()<=SL_MIN_Compra_HOLY && SL_MIN_Compra_HOLY>0))
                 {
                  if(Close_in_One_Direction_Holy==False)
                    {
                     CIERRE_ALL_HOLY(1,1,1);
                     Print("Cierre Total desde pos 1");
                    }
                  else
                    {
                     CIERRE_ALL_HOLY(1,0,1);
                     Print("Cierre solo Compras desde pos 1");
                    }
                  break;
                 }
              }
           }
        }
     }

   if(TickHistoryNew>0 && TypeOrdenHistoryNew==1)
     {
      if((Ask>=SL_MAX_Venta_HOLY && SL_MAX_Venta_HOLY>0) || (Ask<=TP_MIN_Venta_HOLY && TP_MIN_Venta_HOLY>0))
        {
         for(int ocsHOLYv=OrdersHistoryTotal()-1;ocsHOLYv>=0;ocsHOLYv--)
           {
            if(!OrderSelect(ocsHOLYv,SELECT_BY_POS,MODE_HISTORY))Print("Error en la seleccion de Orden, ConfirmaCierreTP_SL_HOLY code 3");
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
              {
               if((OrderType()==1 && OrderCloseTime()>=TiempoHOLYInicioCiclo1VENTAS && OrderClosePrice()<=TP_MIN_Venta_HOLY && TP_MIN_Venta_HOLY>0) ||
                  (OrderType()==1 && OrderCloseTime()>=TiempoHOLYInicioCiclo1VENTAS && OrderClosePrice()>=SL_MAX_Venta_HOLY && SL_MAX_Venta_HOLY>0))
                 {
                  if(Close_in_One_Direction_Holy==False)
                    {
                     CIERRE_ALL_HOLY(1,1,1);
                     Print("Cierre total desde Pos 2");
                    }
                  else
                    {
                     CIERRE_ALL_HOLY(0,1,1);
                     Print("Cierre solo ventas desde Pos 2");
                    }
                  break;
                 }
              }
           }
        }
     }

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                EQUITY_PAR  HOLY                                   |
//+------------------------------------------------------------------+
void EQUITY_PAR_HOLY()
  {
   double EquityPar_HOLY_Money2=0;

   if(AllowMoneyManagement_Holy)
     {
      double tLots=0;
      int cant=0;
      for(int epHOLY=OrdersTotal()-1;epHOLY>=0;epHOLY--)
        {
         if(!OrderSelect(epHOLY,SELECT_BY_POS,MODE_TRADES))Print("No se pudo Seleccionar la orden en la parte del code # EquityParHOLY 0");
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
           {
            tLots+=OrderLots();
            cant+=1;
           }
        }
      if(cant>0)
        {
         EquityPar_HOLY_Money2=((tLots/cant)*EquityPar_HOLY_Money)/(MathMax(Lots_Cycle1_HOLY,Lots_Cycle2_HOLY));
        }
      if(cant==0)
        {
         EquityPar_HOLY_Money2=EquityPar_HOLY_Money;
        }
     }

   if(!AllowMoneyManagement_Holy)EquityPar_HOLY_Money2=EquityPar_HOLY_Money;

   double ProfitDelParHOLY=0;
   double LotesCpHOLY=0;
   double LotesVpHOLY=0;
   for(int epHOLY=OrdersTotal()-1;epHOLY>=0;epHOLY--)
     {
      if(!OrderSelect(epHOLY,SELECT_BY_POS,MODE_TRADES))Print("No se pudo Seleccionar la orden en la parte del code # EquityParHOLY 1");
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
        {
         ProfitDelParHOLY+=OrderProfit()+OrderCommission()+OrderSwap();

         if(OrderType()==0)
           {
            LotesCpHOLY+=OrderLots();
           }

         if(OrderType()==1)
           {
            LotesVpHOLY+=OrderLots();
           }
        }
     }

   if(ProfitDelParHOLY>0 && ProfitDelParHOLY>EquityPar_HOLY_Money2)
     {
      if(QuiebreEquityParHOLY==0)
        {
         if(LotesCpHOLY>LotesVpHOLY)QuiebreEquityParHOLY=Bid;
         if(LotesCpHOLY<LotesVpHOLY)QuiebreEquityParHOLY=Ask;
        }
      if((Trailing_Equity_Par_HOLY==False) || (Trailing_Equity_Par_HOLY==True && Pips_Trailing_EquityPar_HOLY<=0))
        {
         CIERRE_ALL_HOLY(1,1,1);
         Print("Cierre por equity 003");
         return;
        }

      if(Trailing_Equity_Par_HOLY==True && Pips_Trailing_EquityPar_HOLY>0 && QuiebreEquityParHOLY>0)
        {
         if(LotesCpHOLY>LotesVpHOLY)
           {
            if(Bid-QuiebreEquityParHOLY>((Pips_Trailing_EquityPar_HOLY*Mult)*Point))
              {
               QuiebreEquityParHOLY=Bid-((Pips_Trailing_EquityPar_HOLY*Mult)*Point);
              }

            if(Bid<QuiebreEquityParHOLY)
              {
               QuiebreEquityParHOLY=0;
               Print("la Ganancia del par HOLY es ",ProfitDelParHOLY," la base del cierre, dependiendo del lotaje era ",EquityPar_HOLY_Money2);
               CIERRE_ALL_HOLY(1,1,1);
              }
           }

         if(LotesVpHOLY>LotesCpHOLY)
           {
            if(QuiebreEquityParHOLY-Ask>((Pips_Trailing_EquityPar_HOLY*Mult)*Point))
              {
               QuiebreEquityParHOLY=Ask+((Pips_Trailing_EquityPar_HOLY*Mult)*Point);
              }

            if(Ask>QuiebreEquityParHOLY)
              {
               QuiebreEquityParHOLY=0;
               Print("la Ganancia del par HOLY es ",ProfitDelParHOLY,"  la base del cierre, dependiendo del lotaje era  ",EquityPar_HOLY_Money2);
               CIERRE_ALL_HOLY(1,1,1);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FIND_NEW_REOPEN_HOLY()
  {
   double M=1;
   CalculateOrders_HOLY();

   for(int lp=1;lp<=ArraySize(ListaPendientes_H);lp++)
     {
      for(int i=0;i<OrdersTotal();i++)
        {
         if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))Print("Error al  Seleccionar la orden, Find_Reopen code 0.1");
         else
           {
            if(OrderType()==0 || OrderType()==1)
              {
               if(OrderTicket()==ListaPendientes_H[lp-1])
                 {
                  if(OrderType()==0)
                    {
                     if((OrderStopLoss()!=0 && OrderStopLoss()>SL_MIN_Compra_HOLY) || (SL_MIN_Compra_HOLY==0))SL_MIN_Compra_HOLY=OrderStopLoss();
                     if((OrderTakeProfit()!=0 && OrderTakeProfit()<TP_MAX_Compra_HOLY) || (TP_MAX_Compra_HOLY==0))TP_MAX_Compra_HOLY=OrderStopLoss();
                    }

                  if(OrderType()==1)
                    {
                     if((OrderStopLoss()!=0 && OrderStopLoss()<SL_MAX_Venta_HOLY) || (SL_MAX_Venta_HOLY==0))SL_MAX_Venta_HOLY=OrderStopLoss();
                     if((OrderTakeProfit()!=0 && OrderTakeProfit()>TP_MIN_Venta_HOLY) || (TP_MIN_Venta_HOLY==0))TP_MIN_Venta_HOLY=OrderTakeProfit();
                    }
                 }
              }
           }
        }
     }

   if((TicketHoly_B==0 && TicketHoly_S==0) || (TicketHoly_B==0 && TicketHoly_S>=Max_Trades_Per_Cycle_HOLY && Reopen_Multiples_Trades_Holy) || (TicketHoly_S==0 && TicketHoly_B>=Max_Trades_Per_Cycle_HOLY && Reopen_Multiples_Trades_Holy))
     {
      if(UltimoTicketCerrado!=0 && TiempoAviso_HOLY!=0)
        {
         if(Orders_Type_Reopen_Holy==Direct_H)
           {
            if(!OrderSelect(UltimoTicketCerrado,SELECT_BY_TICKET,MODE_HISTORY))Print("Error al seleccionar el ticket, Code FindNewReopen 0");
            else
              {
               if(OrderType()==0)
                 {
                  if(TicketHoly_S>0)M=Multiplier_Factor_Lots_holy;
                  double lotFin5=NormalizeDouble(Lots_Cycle1_HOLY*M,2);
                  if(lotFin5>MAXLOTS())lotFin5=MAXLOTS();
                  if(lotFin5>MarketInfo(NULL,MODE_MAXLOT))lotFin5=MarketInfo(NULL,MODE_MAXLOT);
                  if(lotFin5<MarketInfo(NULL,MODE_MINLOT))lotFin5=MarketInfo(NULL,MODE_MINLOT);
                  if(QuiebreCompraHoly==0)QuiebreCompraHoly=Ask;
                  if(Ask<QuiebreCompraHoly)QuiebreCompraHoly=Ask;
                  if(Ask>QuiebreCompraHoly && Ask-QuiebreCompraHoly>((Pips_Movement_ReOpen_holy*Mult)*Point))
                    {
                     TRADE_DIRECTA_HOLY(lotFin5,0,Pips_SL_HOLY_Cycle1*Mult,Pips_TP_HOLY_Cycle1*Mult,"H_G",Comentarios_TradeS_Reopen2);
                     TiempoHOLYInicioCiclo1COMPRAS=TimeCurrent();
                     BB+=1;
                     Print("TRADE 10A  ","  ",BB);
                     return;
                    }
                 }

               if(OrderType()==1)
                 {
                  if(TicketHoly_B>0)M=Multiplier_Factor_Lots_holy;
                  double lotFin6=NormalizeDouble(Lots_Cycle1_HOLY*M,2);
                  if(lotFin6>MAXLOTS())lotFin6=MAXLOTS();
                  if(lotFin6>MarketInfo(NULL,MODE_MAXLOT))lotFin6=MarketInfo(NULL,MODE_MAXLOT);
                  if(lotFin6<MarketInfo(NULL,MODE_MINLOT))lotFin6=MarketInfo(NULL,MODE_MINLOT);
                  if(QuiebreVentaHoly==0)QuiebreVentaHoly=Bid;
                  //Print(Bid,"   ",QuiebreVentaHoly);
                  if(Bid>QuiebreVentaHoly)QuiebreVentaHoly=Bid;
                  if(Bid<QuiebreVentaHoly && QuiebreVentaHoly-Bid>((Pips_Movement_ReOpen_holy*Mult)*Point))
                    {
                     TRADE_DIRECTA_HOLY(lotFin6,1,Pips_SL_HOLY_Cycle1*Mult,Pips_TP_HOLY_Cycle1*Mult,"H_G",Comentarios_TradeS_Reopen2);
                     TiempoHOLYInicioCiclo1VENTAS=TimeCurrent();
                     BB+=1;
                     Print("TRADE 11A  ","  ",BB);
                     return;
                    }
                 }
              }
           }

         if(Orders_Type_Reopen_Holy==Pending_H)
           {
            if(!OrderSelect(UltimoTicketCerrado,SELECT_BY_TICKET,MODE_HISTORY))Print("Error al seleccionar el ticket, Code FindNewReopen 2");
            else
              {
               if(MathMax(Close[CandleOperation_HOLY]-MediaRapidaHoly,MediaRapidaHoly-Close[CandleOperation_HOLY])<(Pips_Movement_ReOpen_holy*Mult)*Point)
                 {
                  if(TicketHoly_BS==0 && TicketHoly_SS==0)
                    {
                     if(TicketHoly_S>0 || TicketHoly_B>0)M=Multiplier_Factor_Lots_holy;
                     double lotFin7=NormalizeDouble(Lots_Cycle1_HOLY*M,2);
                     if(lotFin7>MAXLOTS())lotFin7=MAXLOTS();
                     if(lotFin7>MarketInfo(NULL,MODE_MAXLOT))lotFin7=MarketInfo(NULL,MODE_MAXLOT);
                     if(lotFin7<MarketInfo(NULL,MODE_MINLOT))lotFin7=MarketInfo(NULL,MODE_MINLOT);

                     TRADE_PENDIENTE_HOLY(Pips_Distance_Pending_Holy*Mult,lotFin7,4,Pips_SL_HOLY_Cycle1*Mult,Pips_TP_HOLY_Cycle1*Mult,"H_Gp",Comentarios_TradeS_Reopen2);
                     TRADE_PENDIENTE_HOLY(Pips_Distance_Pending_Holy*Mult,lotFin7,5,Pips_SL_HOLY_Cycle1*Mult,Pips_TP_HOLY_Cycle1*Mult,"H_Gp",Comentarios_TradeS_Reopen2);
                     BB+=1;
                     Print("TRADE 12A  ","  ",BB);
                    }
                 }
              }
           }
        }
     }

   if(TicketHoly_B>0 || TicketHoly_S>0)
     {
      if((TicketHoly_BS==0 && TicketHoly_SS>0) || (TicketHoly_BS>0 && TicketHoly_SS==0))
        {
         Print("Cierre por Reopen 005");
         CIERRE_ALL_HOLY(0,0,1);
        }
     }

   if(TicketHoly_BS>0 || TicketHoly_SS>0)
     {
      ArrayResize(ListaPendientes_H,1);
      ListaPendientes_H[0]=0;
      for(int i=0;i<OrdersTotal();i++)
        {
         if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))Print("Error al  Seleccionar la orden, Find_Reopen code 0.1");
         else
           {
            if(OrderType()==2 || OrderType()==3 || OrderType()==4 || OrderType()==5)
              {
               int aslp=ArraySize(ListaPendientes_H);
               ArrayResize(ListaPendientes_H,aslp+1);
               ListaPendientes_H[aslp-1]=OrderTicket();
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GANANCIA_MEDIA()
  {
   double Profits_Compras=0;
   double Profits_Ventas=0;

   CalculateOrders_HOLY();
   if(TicketHoly_B>0 && TicketHoly_S>0)
     {
      for(int GM=OrdersTotal()-1;GM>=0;GM--)
        {
         if(!OrderSelect(GM,SELECT_BY_POS,MODE_TRADES))Print("No se pudo Seleccionar la orden en la parte del code # GANANCIAMEDIA 0");
         else
           {
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
              {
               if(OrderType()==0)
                 {
                  Profits_Compras+=OrderProfit()+OrderCommission()+OrderSwap();
                 }
               if(OrderType()==1)
                 {
                  Profits_Ventas+=OrderProfit()+OrderCommission()+OrderSwap();
                 }
              }
           }
        }
      double Maximo_GananciaMedia=MathMax(Profits_Compras,Profits_Ventas);
      double Minimo_GananciaMedia=MathMin(Profits_Compras,Profits_Ventas);

      if(ActivaGananciaMedia_H==0)
        {
         if(Minimo_GananciaMedia<0 && Maximo_GananciaMedia>0 && Minimo_GananciaMedia*(-1)>Maximo_GananciaMedia)
           {
            if((Maximo_GananciaMedia*100)/(Minimo_GananciaMedia*(-1))>=Activator_percentage_Holy)ActivaGananciaMedia_H=1;
           }
        }
      if(ActivaGananciaMedia_H==1)
        {
         if(Minimo_GananciaMedia<0 && Maximo_GananciaMedia>0 && Minimo_GananciaMedia*(-1)>Maximo_GananciaMedia)
           {
            if((Maximo_GananciaMedia*100)/(Minimo_GananciaMedia*(-1))<=Closing_percentage_Holy)
              {
               Print("Cierre las ganadoras");
               if(Maximo_GananciaMedia==Profits_Compras)
                 {
                  CIERRE_ALL_HOLY(1,0,1);
                  Print("Cierre GANACIA MEDIA Compras");
                 }
               if(Maximo_GananciaMedia==Profits_Ventas)
                 {
                  CIERRE_ALL_HOLY(0,1,1);
                  Print("Cierre GANACIA MEDIA Ventas");
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

void CREATE_INFO_INDI_TF(int X,int Y,int Width,int Height)
  {
   string name="BoxIndiTF";
   string name2="NowIndiTF";
   long BGCOLO=ChartGetInteger(0,CHART_COLOR_BACKGROUND);
   ObjectCreate(name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,X+Width);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,Y+Height);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,Width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,Height);
   ObjectSetInteger(0,name,OBJPROP_CORNER,1);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,BGCOLO);
   ObjectSetInteger(0,name,OBJPROP_COLOR,ClrIndiTF);
   ObjectSetInteger(0,name,OBJPROP_BACK,1);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,5);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,False);

   ObjectCreate(name2,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name2,OBJPROP_XDISTANCE,X+Width-8);
   ObjectSetInteger(0,name2,OBJPROP_YDISTANCE,Y+Height+6);
   ObjectSetInteger(0,name2,OBJPROP_CORNER,1);
   ObjectSetInteger(0,name2,OBJPROP_BACK,0);
   ObjectSetString(0,name2,OBJPROP_TEXT,"Working in"+TxtIndiTF);
   ObjectSetInteger(0,name2,OBJPROP_COLOR,ClrIndiTF);
   ObjectSetInteger(0,name2,OBJPROP_SELECTABLE,False);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                       LOTAJE                                     |
//+------------------------------------------------------------------+
double LOTAJE_Holy(double prevLots)
  {
   if(AllowMoneyManagement_Holy && AccountEquity()>Initial_Deposit_Holy)
     {
      double PorcentajeGanado=((AccountEquity()-Initial_Deposit_Holy)*100)/Initial_Deposit_Holy;
      int VecesMult=(int)MathFloor(PorcentajeGanado/Percent_Step_Holy);
      double lotsFinal=NormalizeDouble(prevLots+(VecesMult*Lots_Increment_Holy),2);
      if(lotsFinal>MarketInfo(NULL,MODE_MAXLOT))lotsFinal=MarketInfo(NULL,MODE_MAXLOT);
      return lotsFinal;
     }
   else
      return prevLots;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                GESTION DEL LOTAJE MAXIMO PERMITIDO               |
//+------------------------------------------------------------------+
double MAXLOTS()
  {
   double MargenPorLote=0;

   while(MargenPorLote==0)
     {
      MargenPorLote=MarketInfo(NULL,MODE_MARGINREQUIRED);
     }
   double MargenLibreTotal=AccountFreeMargin();
   double MargenLimitePropuesta=(MAX_Percent_Expose_Account_Holy*MargenLibreTotal)/100;

   double MaxLotesPorOperacion=NormalizeDouble((MargenLimitePropuesta/MargenPorLote)/Max_Trades_Per_Cycle_HOLY,2);
   return MaxLotesPorOperacion;
  }
//+------------------------------------------------------------------+

void TP_PARCIAL_PPAL()
  {
   for(int tg3=0;tg3<GlobalVariablesTotal();tg3++)
     {
      string NombreGlobalVariable3=GlobalVariableName(tg3);
      double  TipoPorValor=GlobalVariableGet(NombreGlobalVariable3);
      if(MathMod(TipoPorValor,1)!=0)
        {
         char Typo=-1;
         if((TipoPorValor-200000)>0) Typo=1;
         else Typo=0;

         if(Typo==0)
           {
            if(Bid>TipoPorValor-100000) GlobalVariableDel(NombreGlobalVariable3);
           }

         if(Typo==1)
           {
            if(Ask<TipoPorValor-200000) GlobalVariableDel(NombreGlobalVariable3);
           }
        }
     }

   for(int i=0;i<OrdersTotal();i++)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))Print("No se puede Seleccionar  la orden en TP_Parcial 01");
      else
        {
         if(OrderMagicNumber()==Magic && OrderSymbol()==Symbol())
           {
            if(OrderTakeProfit()>0 && StringSubstr(OrderComment(),0,4)!="from") //si a orden tiene TP y no es una subOrden// si la orden no ha hecho ningun movimiento!
              {
               string FinalString="";
               if(IsTesting()) // si es un test!
                 {
                  if(OrderTicket()<100000)
                    {
                     string TextoTicket=IntegerToString(OrderTicket(),0,'*');
                     int TamaTextoTicket=StringLen(TextoTicket);
                     if(TamaTextoTicket<6)
                       {
                        string ceros="";
                        switch(TamaTextoTicket)
                          {
                           case 1:
                              ceros="00000";
                              //  corte=1;
                              break;

                           case 2:
                              ceros="0000";
                              //  corte=2;
                              break;

                           case 3:
                              ceros="000";
                              //  corte=3;
                              break;

                           case 4:
                              ceros="00";
                              // corte=4;
                              break;

                           case 5:
                              ceros="0";
                              //   corte=5;
                              break;
                          }
                        FinalString=ceros+TextoTicket;
                       }
                    }
                 }
               else //  si es real, y no test
                 {
                  FinalString=(string)OrderTicket();
                 }
               if(!GlobalVariableCheck(FinalString+Comentario+Symbol()))GlobalVariableSet(FinalString+Comentario+Symbol(),1); // Si la variable no esta creada, la crea
               if(GlobalVariableGet(FinalString+Comentario+Symbol())<=(SpacesTP_Holy-1) && MathMod(GlobalVariableGet(FinalString+Comentario+Symbol()),1)==0)// si la variable es menor a el maximo de espacios menos 1
                 {
                  double ubicacion=GlobalVariableGet(FinalString+Comentario+Symbol());
                  double DistanceTotalTP=0;
                  double DistanceParcialTP=0;
                  double LotsACerrar=NormalizeDouble(OrderLots()/Divisor_Lots_Holy,2);
                  if(LotsACerrar<MarketInfo(NULL,MODE_MINLOT))LotsACerrar=MarketInfo(NULL,MODE_MINLOT);

                  if(OrderType()==0)
                    {
                     DistanceTotalTP=OrderTakeProfit()-OrderOpenPrice();
                     DistanceParcialTP=DistanceTotalTP/SpacesTP_Holy;

                     if(Bid>(OrderOpenPrice()+(DistanceParcialTP*ubicacion)))
                       {
                        if(!OrderClose(OrderTicket(),LotsACerrar,Bid,10,Gray))Print("No se pudo cerrar la orden en Cierre Parcial 1 # ",OrderTicket()," por error ",GetLastError());
                        else
                          {
                           GlobalVariableSet(FinalString+Comentario+Symbol(),ubicacion+1.0);
                           GESTION_SL_TPPARCIAL_HOLY(ubicacion,(string)OrderTicket());
                          }
                       }
                    }

                  if(OrderType()==1)
                    {
                     DistanceTotalTP=OrderOpenPrice()-OrderTakeProfit();
                     DistanceParcialTP=DistanceTotalTP/SpacesTP_Holy;

                     if(Ask<(OrderOpenPrice()-(DistanceParcialTP*ubicacion)))
                       {
                        if(!OrderClose(OrderTicket(),LotsACerrar,Ask,10,Gray))Print("No se pudo cerrar la orden en Cierre Parcial 2 # ",OrderTicket()," por error ",GetLastError());
                        else
                          {
                           GlobalVariableSet(FinalString+Comentario+Symbol(),ubicacion+1.0);
                           GESTION_SL_TPPARCIAL_HOLY(ubicacion,(string)OrderTicket());
                          }
                       }
                    }
                 }
               continue;
              }
            //---
            if(OrderTakeProfit()>0 && StringSubstr(OrderComment(),0,4)=="from") // si la orden YA ha hecho Algun movimiento y es una SubOrden
              {
               string ceros2="";
               string FinalString2="";
               if(IsTesting()) // si es un test!
                 {
                  if(OrderTicket()<100000)
                    {
                     string TextoTicket2=IntegerToString(OrderTicket(),0,'*');
                     int TamaTextoTicket2=StringLen(TextoTicket2);
                     if(TamaTextoTicket2<6)
                       {
                        switch(TamaTextoTicket2)
                          {
                           case 1:
                              ceros2="00000";
                              // corte=1;
                              break;

                           case 2:
                              ceros2="0000";
                              //  corte=2;
                              break;

                           case 3:
                              ceros2="000";
                              // corte=3;
                              break;

                           case 4:
                              ceros2="00";
                              //  corte=4;
                              break;

                           case 5:
                              ceros2="0";
                              //  corte=5;
                              break;
                          }
                        FinalString2=ceros2+TextoTicket2;
                       }
                    }
                 }
               else //  si es real, y no test
                 {
                  FinalString2=(string)OrderTicket();
                 }

               string TicketAnteriorInComment2=ceros2+StringSubstr(OrderComment(),6,corte);
               //Print(TicketAnteriorInComment);
               for(int tg2=0;tg2<GlobalVariablesTotal();tg2++)
                 {
                  string NombreGlobalVariable2=GlobalVariableName(tg2);
                  string ResultadoCorteName=StringSubstr(NombreGlobalVariable2,0,corte);
                  //Print("Nombre de la variable "," final   ",OrderComment(),"  Ticket ",TicketAnteriorInComment2," ff  ",ResultadoCorteName,"  Finn");
                  if(ResultadoCorteName==TicketAnteriorInComment2) //si algun comentario tiene el ticket de una variabe global.(Desactualizada-->Actualiza)
                    {
                     double AnteriorPosicion2=GlobalVariableGet(NombreGlobalVariable2);
                     GlobalVariableDel(NombreGlobalVariable2);
                     GlobalVariableSet(FinalString2+Comentario+Symbol(),AnteriorPosicion2);
                     break;
                    }
                 }

               if(GlobalVariableGet(FinalString2+Comentario+Symbol())<=(SpacesTP_Holy) && MathMod(GlobalVariableGet(FinalString2+Comentario+Symbol()),1)==0)// si la variable es menor a el maximo de espacios menos 1
                 {
                  double ubicacion2=GlobalVariableGet(FinalString2+Comentario+Symbol());
                  double DistanceTotalTP2=0;
                  double DistanceParcialTP2=0;
                  double LotsACerrar2=NormalizeDouble(OrderLots()/Divisor_Lots_Holy,2);
                  if(LotsACerrar2<MarketInfo(NULL,MODE_MINLOT))LotsACerrar2=MarketInfo(NULL,MODE_MINLOT);

                  if(OrderType()==0)
                    {
                     DistanceTotalTP2=OrderTakeProfit()-OrderOpenPrice();
                     DistanceParcialTP2=DistanceTotalTP2/SpacesTP_Holy;

                     if(Bid>(OrderOpenPrice()+(DistanceParcialTP2*ubicacion2)))
                       {
                        if(!OrderClose(OrderTicket(),LotsACerrar2,Bid,10,Gray))Print("No se pudo cerrar la orden en Cierre Parcial 1 # ",OrderTicket()," por error ",GetLastError());
                        else
                          {
                           GlobalVariableSet(FinalString2+Comentario+Symbol(),ubicacion2+1.0);
                           GESTION_SL_TPPARCIAL_HOLY(ubicacion2,(string)OrderTicket());
                           if(ubicacion2==SpacesTP_Holy-1)
                             {
                              double VF=OrderTakeProfit()+100000.0;
                              GlobalVariableSet(FinalString2+Comentario+Symbol(),VF);
                             }
                          }
                       }
                    }

                  if(OrderType()==1)
                    {
                     DistanceTotalTP2=OrderOpenPrice()-OrderTakeProfit();
                     DistanceParcialTP2=DistanceTotalTP2/SpacesTP_Holy;

                     if(Ask<(OrderOpenPrice()-(DistanceParcialTP2*ubicacion2)))
                       {
                        if(!OrderClose(OrderTicket(),LotsACerrar2,Ask,10,Gray))Print("No se pudo cerrar la orden en Cierre Parcial 2 # ",OrderTicket()," por error ",GetLastError());
                        else
                          {
                           GlobalVariableSet(FinalString2+Comentario+Symbol(),ubicacion2+1.0);
                           GESTION_SL_TPPARCIAL_HOLY(ubicacion2,(string)OrderTicket());
                           if(ubicacion2==SpacesTP_Holy-1)
                             {
                              double VF=OrderTakeProfit()+200000.0;
                              GlobalVariableSet(FinalString2+Comentario+Symbol(),VF);
                             }
                          }
                       }
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|               GESTION SL_TP_PARCIAL                              |
//+------------------------------------------------------------------+
void GESTION_SL_TPPARCIAL_HOLY(double ubic,string NumeroOrden)
  {
   int NOrder=0;
   for(int bgsl=0;bgsl<OrdersTotal();bgsl++)
     {
      if(!OrderSelect(bgsl,SELECT_BY_POS,MODE_TRADES))Print("no se pudo seleccionar la orden en gestion SL del TPPARCIAL");
      else
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,4)=="from" && StringSubstr(OrderComment(),6,0)==NumeroOrden)
           {
            NOrder=OrderTicket();
            break;
           }
        }
     }
   if(NOrder>0)
     {
      if(!OrderSelect(NOrder,SELECT_BY_TICKET))Print("No se pudo selecciona la orden en gestion del SL del TPPARCIAL");
      else
        {
         if(Allow_play_SL_Holy)
           {
            if(OrderType()==0)
              {
               double espacioEntreTps=(OrderTakeProfit()-OrderOpenPrice())/SpacesTP_Holy;

               if(Mode_SL_TP_Parcial_Holy==Modo_Step_Step)
                 {
                  if(!OrderStopLoss() || OrderStopLoss()<(OrderOpenPrice()-(espacioEntreTps*((SpacesTP_Holy+1)-ubic))))
                    {
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(espacioEntreTps*((SpacesTP_Holy+1)-ubic)),OrderTakeProfit(),0,Gray))Print("no se logro modificar la orden en GESTION del SL del TPPARCIAL");
                    }
                 }

               if(Mode_SL_TP_Parcial_Holy==Modo_one_Step && ubic==Ubicacion_BreakEven_Holy)
                 {
                  if(!OrderStopLoss() || OrderStopLoss()<OrderOpenPrice())
                    {
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Gray))Print("no se logro modificar la orden en GESTION del SL del TPPARCIAL");
                    }
                 }
              }

            if(OrderType()==1)
              {
               double espacioEntreTps=(OrderOpenPrice()-OrderTakeProfit())/SpacesTP_Holy;

               if(Mode_SL_TP_Parcial_Holy==Modo_Step_Step)
                 {
                  if(!OrderStopLoss() || OrderStopLoss()>(OrderOpenPrice()+(espacioEntreTps*((SpacesTP_Holy+1)-ubic))))
                    {
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(espacioEntreTps*((SpacesTP_Holy+1)-ubic)),OrderTakeProfit(),0,Gray))Print("no se logro modificar la orden en GESTION del SL del TPPARCIAL 2");
                    }
                 }

               if(Mode_SL_TP_Parcial_Holy==Modo_one_Step && ubic==Ubicacion_BreakEven_Holy)
                 {
                  if(!OrderStopLoss() || OrderStopLoss()>OrderOpenPrice())
                    {
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Gray))Print("no se logro modificar la orden en GESTION del SL del TPPARCIAL 2");
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
void CREATEBUTTONS()
  {
   string name1="CloseAllButton";
   string name2="CloseBuyButton";
   string name3="CloseSellButton";

   ObjectCreate(0,name1,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name1,OBJPROP_CORNER,1);
   ObjectSetInteger(0,name1,OBJPROP_XDISTANCE,250);
   ObjectSetInteger(0,name1,OBJPROP_YDISTANCE,105);
   ObjectSetInteger(0,name1,OBJPROP_XSIZE,70);
   ObjectSetInteger(0,name1,OBJPROP_YSIZE,40);
   ObjectSetString(0,name1,OBJPROP_TEXT,"Close All");

   ObjectSetInteger(0,name1,OBJPROP_COLOR,White);
   ObjectSetInteger(0,name1,OBJPROP_BGCOLOR,Red);
   ObjectSetInteger(0,name1,OBJPROP_BORDER_COLOR,Red);
   ObjectSetInteger(0,name1,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name1,OBJPROP_BACK,false);
   ObjectSetInteger(0,name1,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name1,OBJPROP_STATE,false);
   ObjectSetInteger(0,name1,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,name1,OBJPROP_SELECTABLE,false);

   ObjectCreate(0,name2,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name2,OBJPROP_CORNER,1);
   ObjectSetInteger(0,name2,OBJPROP_XDISTANCE,170);
   ObjectSetInteger(0,name2,OBJPROP_YDISTANCE,105);
   ObjectSetInteger(0,name2,OBJPROP_XSIZE,70);
   ObjectSetInteger(0,name2,OBJPROP_YSIZE,40);
   ObjectSetString(0,name2,OBJPROP_TEXT,"Close Buy");

   ObjectSetInteger(0,name2,OBJPROP_COLOR,White);
   ObjectSetInteger(0,name2,OBJPROP_BGCOLOR,Orange);
   ObjectSetInteger(0,name2,OBJPROP_BORDER_COLOR,Orange);
   ObjectSetInteger(0,name2,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name2,OBJPROP_BACK,false);
   ObjectSetInteger(0,name2,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name2,OBJPROP_STATE,false);
   ObjectSetInteger(0,name2,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,name2,OBJPROP_SELECTABLE,false);

   ObjectCreate(0,name3,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name3,OBJPROP_CORNER,1);
   ObjectSetInteger(0,name3,OBJPROP_XDISTANCE,90);
   ObjectSetInteger(0,name3,OBJPROP_YDISTANCE,105);
   ObjectSetInteger(0,name3,OBJPROP_XSIZE,70);
   ObjectSetInteger(0,name3,OBJPROP_YSIZE,40);
   ObjectSetString(0,name3,OBJPROP_TEXT,"Close Sell");

   ObjectSetInteger(0,name3,OBJPROP_COLOR,White);
   ObjectSetInteger(0,name3,OBJPROP_BGCOLOR,Orange);
   ObjectSetInteger(0,name3,OBJPROP_BORDER_COLOR,Orange);
   ObjectSetInteger(0,name3,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name3,OBJPROP_BACK,false);
   ObjectSetInteger(0,name3,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name3,OBJPROP_STATE,false);
   ObjectSetInteger(0,name3,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,name3,OBJPROP_SELECTABLE,false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CREATEINFOBUTTONS(double Precio,string secue,int Distancia)
  {
   string name="InfoButton"+secue;
   string Precio2=DoubleToStr(Precio,2);

   if(ObjectFind(0,name)<=-1)
     {
      ObjectCreate(name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,10+(Distancia*85)+60);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,150);
      ObjectSetInteger(0,name,OBJPROP_CORNER,1);
      ObjectSetInteger(0,name,OBJPROP_BACK,0);
      ObjectSetString(0,name,OBJPROP_TEXT,Precio2);
      ObjectSetInteger(0,name,OBJPROP_COLOR,Gray);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,False);
     }

   else
     {
      if((string)ObjectGet(name,OBJPROP_TEXT)!=Precio2)
        {
         ObjectSetString(0,name,OBJPROP_TEXT,Precio2);
        }
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ManageEvents()
  {
// If exitBtn is clicked execute function ExitEA()
   if(guiIsClicked(hwnd,exitBtn))ExitEA();

// If loginBtn is clicked execute function LoginEA()
   if(guiIsClicked(hwnd,loginBtn)) LoginEA();
  }
//+------------------------------------------------------------------+
//|                  BUILD INTERFACE                                 |
//+------------------------------------------------------------------+
void BuildInterface()
  {
   loginPanel=guiAdd(hwnd,"label",gUIXPosition,gUIYPosition+20,180,100,"");
   guiSetBgColor(hwnd,loginHeader,DarkBlue);
   guiSetTextColor(hwnd,loginHeader,White);
   guiSetBgColor(hwnd,loginPanel,DarkSlateGray);
   loginHeader=guiAdd(hwnd,"label",gUIXPosition,gUIYPosition,180,20,"Enter PASS for Close:");
   passwordTextField=guiAdd(hwnd,"text",gUIXPosition+10,gUIYPosition+20,160,25,"12345");
   loginBtn=guiAdd(hwnd,"button",gUIXPosition+105,gUIYPosition+50,70,40,"");
   guiSetBorderColor(hwnd,loginBtn,RoyalBlue);
   guiSetBgColor(hwnd,loginBtn,Blue);
   guiSetTextColor(hwnd,loginBtn,White);
   guiSetText(hwnd,loginBtn,"CLOSE",25,"Arial Bold");

   exitBtn=guiAdd(hwnd,"button",gUIXPosition+10,gUIYPosition+50,70,40,"");
   guiSetBorderColor(hwnd,exitBtn,OrangeRed);
   guiSetBgColor(hwnd,exitBtn,Red);
   guiSetTextColor(hwnd,exitBtn,Black);
   guiSetText(hwnd,exitBtn,"CANCEL",17,"Arial Bold");
  }
// Windows/MT4 function to exit EA (advanced)

void ExitEA()
  {
//Alert("you cancel the CLOSE trades");
   if(hwnd>0) guiRemoveAll(hwnd);
   guiCleanup(hwnd);
  }
// MT4GUI function check textfields (username & password), MT4 pop-up alerts
//+-------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LoginEA()
  {
   if(guiGetText(hwnd,passwordTextField)==password)
     {
      Print("Authorization successful, CLOSE With Buttons");
      guiRemoveAll(hwnd);authenticationFail=0;
      if(TypeClose==3)
        {
         CIERRE_ALL_HOLY(1,1,1);
         ObjectSetInteger(0,"CloseAllButton",OBJPROP_STATE,false);
         Print("CIERRE CON BOTON ALL");
         if(Allow_Auto_Stop_Restart_ManualTRADE && Modo_AutoStop_Button==RemoveEA_Button)
           {
            UltimoTicketCerrado=0;
            UltimoAutoStop_ManualTrade=TimeCurrent();
            Print("El Expert sera removido, debido a que se ha activado en AutoStop en el cierre all Button");
            ExpertRemove();
           }
         if(Allow_Auto_Stop_Restart_ManualTRADE && Modo_AutoStop_Button==RestartEA_Button)
           {
            UltimoTicketCerrado=0;
            UltimoAutoStop_ManualTrade=TimeCurrent();
            InicioMute_Button=Time[0];
            Print("El Expert estara Inactivo por ",Velas_Mute_Button," Velas");
           }
        }
      if(TypeClose==0)
        {
         CIERRE_ALL_HOLY(1,0,0);
         ObjectSetInteger(0,"CloseBuyButton",OBJPROP_STATE,false);
         Print("CIERRE CON BOTON COMPRAS");
        }
      if(TypeClose==1)
        {
         CIERRE_ALL_HOLY(0,1,0);
         ObjectSetInteger(0,"CloseSellButton",OBJPROP_STATE,false);
         Print("CIERRE CON BOTON VENTAS");
        }
      TypeClose=-1;
     }
   else if(authenticationFail==0)
     {Alert("Authorization failed, please try again (you have 2 of 2 retries left)"); authenticationFail++;}
   else if(authenticationFail==1)
     {Alert("Authorization failed, please try again (you have 1 of 2 retries left)"); authenticationFail++;}
   else if(authenticationFail==2)
     {
      Alert("Authentication failed 3 times, this blocks your login");
      guiEnable(hwnd,loginBtn,0);
      Sleep(5000);
      if(hwnd>0) guiRemoveAll(hwnd);
      guiCleanup(hwnd);
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                EQUITY SL                                         |
//+------------------------------------------------------------------+
void EQUITY_SL()
  {
   double Perdidas=0;
   for(int o=OrdersTotal()-1;o>=0;o--)
     {
      if(!OrderSelect(o,SELECT_BY_POS,MODE_TRADES))Print("No se pudo Seleccionar la orden en la parte del cod SL_EQUITY # 1");
      else
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && StringSubstr(OrderComment(),0,3)==PrefijoHOLY)
           {
            Perdidas+=(OrderProfit()+OrderCommission()+OrderSwap());
           }
        }
     }
   if(Perdidas<0 && Perdidas*(-1)>=Target_Equity_SL_Holy)
     {
      CIERRE_ALL_HOLY(1,1,1);
      Print("Cierre por SLEQUITY HOLY");
      if(Allow_Auto_Stop_Restart_EquitySL && Modo_AutoStop_SLEquity==RemoveEA_SLEquity)
        {
         UltimoTicketCerrado=0;
         UltimoAutoStop_SLEQUITY=TimeCurrent();
         Print("El Expert sera removido, debido a que se ha activado en AutoStop en el SL_EQUITY");
         ExpertRemove();
        }
      if(Allow_Auto_Stop_Restart_EquitySL && Modo_AutoStop_SLEquity==RestartEA_SLEquity)
        {
         UltimoTicketCerrado=0;
         UltimoAutoStop_SLEQUITY=TimeCurrent();
         InicioMute_SLEquity=Time[0];
         Print("El Expert  estara Inactivo por ",Velas_Mute_SLEquity," Velas");
        }
     }
  }
//+------------------------------------------------------------------+
