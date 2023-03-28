//
//  BingoCombos.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-11-08.
//

import Foundation

/*
 Contains all the information for bingo win combos
 */

let rowKey = "Five-in-a-Row"
let xKey = "X Combo"
let cornersKey = "4 Corners"
let ringKey = "Ring"
let blackoutKey = "Blackout"

let keys = [rowKey, xKey, cornersKey, ringKey, blackoutKey]

let rowCombo = [31, 992, 31744, 1015808, 32505856, 1082401, 2164802, 4329604, 8659208, 17318416, 1118480, 17043521]
let xCombo = [18157905]
let cornersCombo = [17825809]
let ringCombo = [33080895]
let blackoutCombo = [33554431]

let winCombos = [
    rowKey: rowCombo,
    xKey: xCombo,
    cornersKey: cornersCombo,
    ringKey: ringCombo,
    blackoutKey: blackoutCombo
]

