/*
 * Aeon - Open Source Reconfigurable Computer
 * Copyright (C) 2013-2015 Dmitriy Schapotschkin (ilovespeccy@speccyland.net)
 * Project Homepage: http://www.speccyland.net
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "hal.h"
#include "usb_handler.h"
#include "timer.h"
#include "ui.h"

int main(void)
{
   ioInit();
   ppsInit();
   spiInit();
   commInit();
   uartInit();
   iicInit();
   timerInit();
   usbInit();

   while(1)
   {
      /// usbHandler отвечает за коммуникацию с платой через USB и используется
      /// для отладки, первого пуска и конфигурирования FPGA
      ///
      /// uiHandler отвечает за user interface, тоесть выводит меню, список
      /// прошивок и другое в таком духе...
      ///
      /// usbHandler возвращает значение lock (=1 при конфигурированиее FPGA)
      /// uiHandler вызывается только при lock=0, иначе проблемы с передачей
      /// данных так как для конфигурирования FPGA и коммуникации PIC'а с FPGA
      /// используется один и тот же SPI.
      /// Параметр lock по-умолчанию равен 0 и может быть изменён только извне,
      /// через USB.

      if (!usbHandler())   // Lock from usbHandler
         uiHandler();

      /// На данный момент для обработки различных компонентов, которые будут
      /// реализованы в сервисной прошивке (например эмулятор дисковода ПК
      /// "Корвет ПК-8020") зарезервировано место в uiHandler. Но скорее всего
      /// эта часть будет перенесена сюда, и тоже, как и uiHandler, будет
      /// вызываться только при lock=0. Обработчик назову deviceHandler() ;)
   }
}
