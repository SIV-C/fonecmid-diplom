
#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Выполняет заполнение табличной части документа
Процедура ВКМ_ВыполнитьАвтозаполнение() Экспорт
	
	НоменклатураАбонентскаяПлата = ВКМ_НоменклатураАбонентскаяПлата();
	НоменклатураРаботыСпециалиста = ВКМ_НоменклатураРаботыСпециалиста();
	
	Если Не ЗначениеЗаполнено(НоменклатураАбонентскаяПлата) Тогда
		ОбщегоНазначения.СообщитьПользователю("Не заполнена константа: Номенклатура абонентская плата");
		Возврат; 
	КонецЕсли;
	
	Если Не ЗначениеЗаполнено(НоменклатураРаботыСпециалиста) Тогда 
		ОбщегоНазначения.СообщитьПользователю("Не заполнена константа: Номенклатура работы специалиста");
		Возврат; 
	КонецЕсли; 
	  
	// ++ Проверка действия договора
	ДанныеДоговора = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(Договор, 
		"ВКМ_НачалоДействияДоговора, ВКМ_КонецДействияДоговора, ВКМ_СуммаАбонентскойПлаты");
	
	Если ДанныеДоговора.ВКМ_НачалоДействияДоговора < Дата 
		ИЛИ ДанныеДоговора.ВКМ_КонецДействияДоговора > Дата Тогда		
			ОбщегоНазначения.СообщитьПользователю("Договр не действует на дату реализации");
			Возврат; 
	КонецЕсли;
	// -- Проверка действия договора	  
	
	Услуги.Очистить();
		
	Если ДанныеДоговора.ВКМ_СуммаАбонентскойПлаты > 0 Тогда  	
		НоваяСтрока = Услуги.Добавить();
		НоваяСтрока.Номенклатура = НоменклатураАбонентскаяПлата;
		НоваяСтрока.Сумма = ДанныеДоговора.ВКМ_СуммаАбонентскойПлаты;	
	КонецЕсли;
	
	СуммаРаботСпециалиста = ВКМ_РаботыСпециалиста(); 
	
	Если СуммаРаботСпециалиста > 0 Тогда	
		НоваяСтрока = Услуги.Добавить();
		НоваяСтрока.Номенклатура = НоменклатураРаботыСпециалиста;
		НоваяСтрока.Сумма = СуммаРаботСпециалиста; 	
	КонецЕсли;
			
	СуммаДокумента = Товары.Итог("Сумма") + Услуги.Итог("Сумма");
		
КонецПроцедуры	

#КонецОбласти

#Область ОбработчикиСобытий

Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
					|	ДоговорыКонтрагентов.Ссылка КАК Ссылка,
					|	ДоговорыКонтрагентов.ВидДоговора КАК ВидДоговора
					|ИЗ
					|	Справочник.ДоговорыКонтрагентов КАК ДоговорыКонтрагентов
					|ГДЕ
					|	ДоговорыКонтрагентов.Ссылка = &Ссылка";
	
	Запрос.УстановитьПараметр("Ссылка", Договор);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Выборка.Следующий();
	
	Если Выборка.ВидДоговора = Перечисления.ВидыДоговоровКонтрагентов.ВКМ_АбонентскоеОбслуживание Тогда
		
		ИндексЭлемента = ПроверяемыеРеквизиты.Найти("Основание");
		ПроверяемыеРеквизиты.Удалить(ИндексЭлемента);
		
	КонецЕсли;
	
КонецПроцедуры

Процедура ОбработкаЗаполнения(ДанныеЗаполнения, ТекстЗаполнения, СтандартнаяОбработка)
	
	Ответственный = Пользователи.ТекущийПользователь();
	
	Если ТипЗнч(ДанныеЗаполнения) = Тип("ДокументСсылка.ЗаказПокупателя") Тогда
		ЗаполнитьНаОснованииЗаказаПокупателя(ДанныеЗаполнения);
	КонецЕсли;
	
КонецПроцедуры

Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)
	
	Если ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;

	СуммаДокумента = Товары.Итог("Сумма") + Услуги.Итог("Сумма");
	
КонецПроцедуры

Процедура ОбработкаПроведения(Отказ, Режим)

	Движения.ОбработкаЗаказов.Записывать = Истина;
	Движения.ОстаткиТоваров.Записывать = Истина;
	Движения.ВКМ_ВыставленныеКОплатеРаботы.Записывать = Истина;
	
	Движение = Движения.ОбработкаЗаказов.Добавить();
	Движение.Период = Дата;
	Движение.Контрагент = Контрагент;
	Движение.Договор = Договор;
	Движение.Заказ = Основание;
	Движение.СуммаОтгрузки = СуммаДокумента;

	Для Каждого ТекСтрокаТовары Из Товары Цикл
		Движение = Движения.ОстаткиТоваров.Добавить();
		Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
		Движение.Период = Дата;
		Движение.Контрагент = Контрагент;
		Движение.Номенклатура = ТекСтрокаТовары.Номенклатура;
		Движение.Сумма = ТекСтрокаТовары.Сумма;
		Движение.Количество = ТекСтрокаТовары.Количество;
	КонецЦикла;
	
	Для Каждого ТекСтрокаУслуги Из Услуги Цикл
		Если ТекСтрокаУслуги.Номенклатура = Константы.ВКМ_НоменклатураРаботыСпециалиста.Получить() Тогда
			Движение = Движения.ВКМ_ВыставленныеКОплатеРаботы.Добавить();
			Движение.Номенклатура = ТекСтрокаУслуги.Номенклатура;
			Движение.Период = Дата;
			Движение.Клиент = Контрагент;
			Движение.Договор = Договор;
			Движение.Сумма = ТекСтрокаУслуги.Сумма;
		КонецЕсли;
	КонецЦикла;
	

КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ВКМ_РаботыСпециалиста()
	
	Запрос = Новый Запрос;
    Запрос.Текст =
	"ВЫБРАТЬ
	|	ВКМ_ВыполненныеКлиентуРаботыОбороты.СуммаОборот КАК Сумма,
	|	ВКМ_ВыполненныеКлиентуРаботыОбороты.Договор КАК Договор
	|ИЗ
	|	РегистрНакопления.ВКМ_ВыполненныеКлиентуРаботы.Обороты(
	|			&ДатаНачала,
	|			&ДатаОкончания,
	|			,
	|			Контрагент = &Контрагент
	|				И Договор = &Договор) КАК ВКМ_ВыполненныеКлиентуРаботыОбороты";
	
	Запрос.УстановитьПараметр("Контрагент", Контрагент);
    Запрос.УстановитьПараметр("Договор", Договор);
    Запрос.УстановитьПараметр("ДатаНачала", НачалоМесяца(Дата));
    Запрос.УстановитьПараметр("ДатаОкончания", КонецМесяца(Дата));
	
	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();
	
	Если Выборка.Количество() = 0 Тогда
		Сумма = 0;
	Иначе				
		Выборка.Следующий();	
		Сумма = Выборка.Сумма;  	
	КонецЕсли;  
	
	Возврат Сумма;
	
КонецФункции


Процедура ЗаполнитьНаОснованииЗаказаПокупателя(ДанныеЗаполнения)
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	               |	ЗаказПокупателя.Организация КАК Организация,
	               |	ЗаказПокупателя.Контрагент КАК Контрагент,
	               |	ЗаказПокупателя.Договор КАК Договор,
	               |	ЗаказПокупателя.СуммаДокумента КАК СуммаДокумента,
	               |	ЗаказПокупателя.Товары.(
	               |		Ссылка КАК Ссылка,
	               |		НомерСтроки КАК НомерСтроки,
	               |		Номенклатура КАК Номенклатура,
	               |		Количество КАК Количество,
	               |		Цена КАК Цена,
	               |		Результат КАК Результат
	               |	) КАК Товары,
	               |	ЗаказПокупателя.Услуги.(
	               |		Ссылка КАК Ссылка,
	               |		НомерСтроки КАК НомерСтроки,
	               |		Номенклатура КАК Номенклатура,
	               |		Количество КАК Количество,
	               |		Цена КАК Цена,
	               |		Результат КАК Результат
	               |	) КАК Услуги
	               |ИЗ
	               |	Документ.ЗаказПокупателя КАК ЗаказПокупателя
	               |ГДЕ
	               |	ЗаказПокупателя.Ссылка = &Ссылка";
	
	Запрос.УстановитьПараметр("Ссылка", ДанныеЗаполнения);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Не Выборка.Следующий() Тогда
		Возврат;
	КонецЕсли;
	
	ЗаполнитьЗначенияСвойств(ЭтотОбъект, Выборка);
	
	ТоварыОснования = Выборка.Товары.Выбрать();
	Пока ТоварыОснования.Следующий() Цикл
		ЗаполнитьЗначенияСвойств(Товары.Добавить(), ТоварыОснования);
	КонецЦикла;
	
	УслугиОснования = Выборка.Услуги.Выбрать();
	Пока ТоварыОснования.Следующий() Цикл
		ЗаполнитьЗначенияСвойств(Услуги.Добавить(), УслугиОснования);
	КонецЦикла;
	
	Основание = ДанныеЗаполнения;
	
КонецПроцедуры

Функция ВКМ_НоменклатураАбонентскаяПлата()
	
	Возврат Константы.ВКМ_НоменклатураАбонентскаяПлата.Получить();
	
КонецФункции

Функция ВКМ_НоменклатураРаботыСпециалиста()
	
	Возврат Константы.ВКМ_НоменклатураРаботыСпециалиста.Получить();
	
КонецФункции

Функция ДанныеПоДоговору()

	ДанныеПоДоговору = Новый Структура("КоличествоЧасов, СуммаКОплате, ЕстьРаботыЗаМесяц");
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	|	ВКМ_ВыполненныеКлиентуРаботыОбороты.КоличествоЧасовОборот,
	|	ВКМ_ВыполненныеКлиентуРаботыОбороты.СуммаКОплатеОборот
	|ИЗ
	|	РегистрНакопления.ВКМ_ВыполненныеКлиентуРаботы.Обороты(&НачалоИнтервала, &КонецИнтервала,, Договор = &Договор) КАК
	|		ВКМ_ВыполненныеКлиентуРаботыОбороты";
	
	Запрос.УстановитьПараметр("НачалоИнтервала", НачалоМесяца(Дата));
	Запрос.УстановитьПараметр("КонецИнтервала", КонецМесяца(Дата));
	Запрос.УстановитьПараметр("Договор", Договор);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Выборка.Количество() = 0 Тогда
		ДанныеПоДоговору.ЕстьРаботыЗаМесяц = Ложь;
	КонецЕсли;
		
	Пока Выборка.Следующий() Цикл
		ДанныеПоДоговору.ЕстьРаботыЗаМесяц = Истина;
		ДанныеПоДоговору.КоличествоЧасов = Выборка.КоличествоЧасовОборот;
		ДанныеПоДоговору.СуммаКОплате = Выборка.СуммаКОплатеОборот;
	КонецЦикла;	
	
	Возврат ДанныеПоДоговору
		
КонецФункции
	

#КонецОбласти

#КонецЕсли
