import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from '../../../services/commons.service';

@Component({
  selector: 'app-caretaker-profile',
  templateUrl: './caretaker-profile.component.html',
  styleUrls: ['./caretaker-profile.component.css']
})
export class CaretakerProfileComponent implements OnInit {

  constructor(private http: HttpClient) { }

  public getCaretaker(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/detailed', httpOptions);
  }

  ngOnInit(): void {
  }

}
