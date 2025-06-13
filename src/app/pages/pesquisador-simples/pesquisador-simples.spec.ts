import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PesquisadorSimples } from './pesquisador-simples';

describe('PesquisadorSimples', () => {
  let component: PesquisadorSimples;
  let fixture: ComponentFixture<PesquisadorSimples>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PesquisadorSimples]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PesquisadorSimples);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
