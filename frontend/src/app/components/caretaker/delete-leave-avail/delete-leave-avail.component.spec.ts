import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DeleteLeaveAvailComponent } from './delete-leave-avail.component';

describe('DeleteLeaveAvailComponent', () => {
  let component: DeleteLeaveAvailComponent;
  let fixture: ComponentFixture<DeleteLeaveAvailComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DeleteLeaveAvailComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DeleteLeaveAvailComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
