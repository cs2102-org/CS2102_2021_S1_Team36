import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-forum',
  templateUrl: './forum.component.html',
  styleUrls: ['./forum.component.css']
})
export class ForumComponent implements OnInit {

  constructor() { }


  fakePosts: any[] = [
    {name: 'Dr Nice', title: 'Postt 1', content: 'brey9qffgfg 5w4 g5erq97qgf93'},
    {name: 'Dr Nicdde', title: 'Postt 1fsd', content: 'brey9qg 54 wg5 4g 54wffgferq97qgf93'},
    {name: 'Dr Nicsfdsfewe', title: 'Postdst 1', content: 'brey9qf 4w g54 wfgferq97qgf93'},
    {name: 'fewfreaafaDr Nice', title: 'Psdsostt 1', content: 'brey954wg 54w g54wg 4qffgferq97qgf93'},
    {name: 'Dr Nfrafice', title: 'Posfwett 1', content: 'brey9qffgfe 4wgw4 g 4 wgrq97qgf93'},
    {name: 'Dr Nfewfrafice', title: 'ddPostt 1', content: 'brey9qff 4g 54 g5gferq97qgf93'},
    {name: 'Dr Nfrsafice', title: 'Pofwefewfwstt 1', content: 'brey954wg 54w g5qffgferq97qgf93'},
    {name: 'Dr Ncdsaice', title: 'Posfsafrsett 1', content: 'brey9 g4w g54  gqffgferq97qgf93'},
    {name: 'Dr Ncsaice', title: 'Postfdt 1', content: 'brey9qffgg  g45w g4ferq97qgf93'},
    {name: 'Dr Ncesaice', title: 'Posfdsftt 1', content: 'brey9qffgtretgrtgferq97qgf93'},
    {name: 'Dr Nbhteaice', title: 'Post31t 1', content: 'brey9qffgfvgrfesgaeerq97qgf93'},
    
  ];

  ngOnInit(): void {
  }

}
