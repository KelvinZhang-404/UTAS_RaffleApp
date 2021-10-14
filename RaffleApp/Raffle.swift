//
//  Raffle.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 19/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import Foundation

public struct Raffle
{
    var raffleID:Int32 = -1
    var name:String
    var description:String
    var drawnMethod:String
    var startDate:String
    var endDate:String
    var status:String
    var ticketAmount:Int32
    var ticketPrice:Double
    var purchaseLimit:Int32
    var image:String
    var winner:String = "no winner"
}
